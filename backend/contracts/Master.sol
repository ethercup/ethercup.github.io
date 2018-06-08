pragma solidity 0.4.19;

contract Master { 
  uint public test = 9999;

  function init()
      public
  {
      test = 12345;
  }

  function ()
      external
      payable
  {
      revert(); 
  }
}