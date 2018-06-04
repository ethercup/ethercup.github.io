// Bytecode origin https://www.reddit.com/r/ethereum/comments/6ic49q/any_assembly_programmers_willing_to_write_a/dj5ceuw/
// Modified version of Vitalik's https://www.reddit.com/r/ethereum/comments/6c1jui/delegatecall_forwarders_how_to_save_5098_on/
// Credits to Jordi Baylina for this way of deploying contracts https://gist.github.com/jbaylina/e8ac19b8e7478fd10cf0363ad1a5a4b3

// Forwarder is slightly modified to only return 256 bytes (8 normal returns)

// Deployed Factory in Kovan: https://kovan.etherscan.io/address/0xaebc118657099e2110c90494f48b3d21329b23eb

// Example of a Forwarder deploy using the Factory: https://kovan.etherscan.io/tx/0xe995dd023c8336685cb819313d933ae8938009f9c8c0e1af6c57b8be06986957
// Just 66349 gas per contract

pragma solidity ^0.4.24;

contract BetFactory {
    event ForwarderDeployed(address forwarderAddress, address targetContract);

    function createBet(address target) returns (address fwdContract) {
        bytes32 b1 = 0x602e600c600039602e6000f33660006000376101006000366000730000000000; // length 27 bytes = 1b
        bytes32 b2 = 0x5af41558576101006000f3000000000000000000000000000000000000000000; // length 11 bytes
       
        uint256 shiftedAddress = uint256(target) * ((2 ** 8) ** 12);   // Shift address 12 bytes to the left
       
        assembly {
            let contractCode := mload(0x40)                 // Find empty storage location using "free memory pointer"
            mstore(contractCode, b1)                        // We add the first part of the bytecode
            mstore(add(contractCode, 0x1b), shiftedAddress) // Add target address
            mstore(add(contractCode, 0x2f), b2)             // Final part of bytecode 
            fwdContract := create(0, contractCode, 0x3A)    // total length 58 dec = 3a
            switch extcodesize(fwdContract) case 0 { invalid() }
        }
       
        ForwarderDeployed(fwdContract, target);
    }

    function createBet2(address _target, bytes _data)
        public
        returns (address proxyContract)
    {
        proxyContract = createProxyImpl(_target, "");
        ForwarderDeployed(proxyContract, _target);

    }
    
    function createProxyImpl(address _target, bytes _data)
        internal
        returns (address proxyContract)
    {
        assembly {
            let contractCode := mload(0x40) // Find empty storage location using "free memory pointer"
           
            mstore(add(contractCode, 0x0b), _target) // Add target address, with a 11 bytes [i.e. 23 - (32 - 20)] offset to later accomodate first part of the bytecode
            mstore(sub(contractCode, 0x09), 0x000000000000000000603160008181600b9039f3600080808080368092803773) // First part of the bytecode, shifted left by 9 bytes, overwrites left padding of target address
            mstore(add(contractCode, 0x2b), 0x5af43d828181803e808314602f57f35bfd000000000000000000000000000000) // Final part of bytecode, offset by 43 bytes

            proxyContract := create(0, contractCode, 60) // total length 60 bytes
            if iszero(extcodesize(proxyContract)) {
                revert(0, 0)
            }
           
            // check if the _data.length > 0 and if it is forward it to the newly created contract
            let dataLength := mload(_data) 
            if iszero(iszero(dataLength)) {
                if iszero(call(gas, proxyContract, 0, add(_data, 0x20), dataLength, 0, 0)) {
                    revert(0, 0)
                }
            }
        }
    }
}

