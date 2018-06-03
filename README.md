Ethercup
========

Bet Ether on your favorite teams for every match of the FIFA worldcup 2018 in Russia.

For each match, a smart contract is deployed on the Ethereum blockchain. By calling its functions you can bet on either team competing in a match. After the match is decided, the payout pool is split among the people who guessed correctly.


![Screenshot of open bet](https://github.com/ethercup/ethercup.github.io/tree/master/screenshots/screenshot_bet_open.png)


Other than betting on the wrong team, there's no way of losing Ether. The design of the deployed Bet smart contracts makes this betting dApp (distributed application) fraud- and tamper-proof! Your bets are safely stored in the smart contracts. The Ether pool will be redistributed once the match result is confirmed. In case of bad case scenarios (match is postponed, external data provider misbehaves, etc), you're always able to get all your Ether back without paying any fee! 

How it works
------------

For every match (bet), a smart contract is deployed on the Ethereum blockchain. Depending on the current stage of the bet, different interactions with the smart contracts are possible for any users, who installed the Metamask browser extension. A bet goes through the following phases:

1. **Inactive**: The bet is deployed on the blockchain but it's too early to place bets.
2. **Open**: The bet opens *1 week* before the match starts. You can bet on either team as often you want with as much Ether as you want. The minimum bet amount is 0.001 Ether, which is about 50cents right now.
3. **Closed/Match playing**: The bet closes *15 min* before the match starts. It is too late to place bets now, as the match is starting soon.
4. **Match finished**: When the regular match time is over, users can activate the smart contract to start fetching the match result from `football-data.org`. If there's no result yet, e.g. because the match includes a penalty shootout at the end and thus lasts longer, the smart contract will retry to fetch the result. Once the final match result is fetched, the result has to be confirmed by the admin. The fetching and confirmation of the match outcome has to be completed within *2 days* after match start. If it takes longer, you can claim refunds.
5. **Payouts**: Once the winner is fetched and confirmed, there's no go-back. The Ether pool is redistributed and a small 1% fee is deducted to (hopefully) cover the deployment costs. Users, who betted on the winning team, can claim their payouts. The bet cannot be cancelled anymore by anyone. But be careful: Your payouts expire after *4 weeks*.

Each phase comes with a timeout. After this timeout, the next phase is entered, or, in case of a missing event in the previous phase (e.g. winner not confirmed), the smart contract switches to the final phase is 'cancelled'. A cancelled bet cannot be re-activated but anyone can get their Ether refunded.

Your bets are safe
------------------
The design of the smart contracts representing the various bets makes betting on Ethercup 100% fraud-proof. There are two outcomes of a bet:

1. The match is finished and the result is first correctly fetched and then confirmed. Subsequently, users can claim their payouts.
2. Something goes wrong, e.g. the match is postponed, the fetching does not return any match results or the result is not confirmed in time. In any of these cases, users get their bets fully refunded without paying any fee!

The owner/admin of the smart contracts is the only person, who can confirm the match result after it is fetched. This 2-phase approach is very secure: On the one hand you don't have to trust the external data provider, because in case he publishes wrong results, the owner of the smart contract disapproves the fetched match result. On the other hand you don't have to trust the owner, because he is only able to tell "yes, this match result is correct" or "no, this result is incorrect". After a single confirmation by the admin, we are either in payout phase (when the fetched winner is confirmed) or your bets are refunded to you (in case the confirmed winner doesn't match with the fetched winner). Win-win!

You can check the smart contract implementation yourself to decide if you want to trust this design.

Handling of bad scenarios
-------------------------
The tamper-proof nature of the Ethereum blockchain makes smart contracts the most trusted part of Ethercup. However, some aspects, i.e. fetching of the match result and confirmation by the admin, introduce human error and sources of potential failure.

Let's walk through these scenarios:
* *The external data provider doesn't deliver any data*:
	Fetching the match result is retried every 1 hour. In case the smart contract is unable to fetch the match result within 24h, the bet switches to "cancelled" and users can claim full refunds of their bets without paying any fee.
* *There are too many attempts to fetch the match result from the external data provider*: The bet smart contracts use both a limited number of fetch attemps as well as a limited Ether balance to pay for fetches (they cost a bit of Ether). Once one of those limitations is reached but the timeout is not reached yet, anyone can refund the smart contract and restart fetching match results by calling a special function of any bet smart contract.
* *The external data provider is broken or even malicious and provides an incorrect match result*:
	The match result must be confirmed by the owner of the smart contract before payouts are possible. If the owner disapproves the fetched match result, the bet switches to "cancelled" and users can claim full refunds of their bets without paying any fee.
* *During the worldcup, the Ethereum network might be congested, leading to exorbitant transaction costs (see Cryptokitties example)*: The default gas price is set to 6GWei. In case this proves to be insufficient, the owner can increase the gas price by calling a special purpose function of the smart contract.
* *The owner (creator of Ethercup) is malicious and wants to steal your funds*: Even if I were a scammer, I would not have the power (given the secure smart contract design) to steal a single penny from you. This is what I can do as owner/admin:
	* Bet on my favorite teams as anyone else can.
    * Confirm a winner: If I don't confirm a winner, the bet will switch to "cancelled" after a timeout of 1 day.
    * Cancel a bet: In case I haven't confirmed a fetched match result yet, I can cancel the bet at any previous stage. I will make use of this power when a match is postponed or any other bad event happens. If the bet is switched to "cancelled" you can claim full refunds of your bets without paying any fee.
    * Change the UI: I built the UI to let you interact with the bet smart contracts in a more convenient way. In case you don't trust the UI (source code is open sourced) and you still think that I could be a scammer, you don't have to use the UI. Feel free to call the smart contracts functions yourself, e.g. by using Ethereum's Mist browser. You can find the smart contract addresses at the bottom of every bet (in the UI) and at the end of this page.
 * *The owner (creator of Ethercup) is replacing the source code or address displayed in the UI in the last second*: I will verify each smart contract I deploy on `etherscan.io`. This means that if you browse a bet smart contract by its address on `etherscan.io`, you will notice a verification checkmark and the corresponding source code of the smart contract. This way you can be sure that behind a bet contract address is indeed the functionality I promise.

Other things to note
--------------------
* Smart contracts can't be changed once they are deployed. In case of a postponed match for example, a new smart contract, which reflects a new match start time, will be deployed and replaces the old contract.
* Smart contracts don't execute code autonomously. This means that fetching of the match result as well as paying out lucky betters, doesn't happen automatically. Instead, you as a user have to call functions of the smart contract to start fetching or to claim payouts. This is why you read 'claim payouts' and 'claim refunds' throughout this how-to. You have to take action in order to get your Ether.
* Transactions on the Ethereum blockchain cost small fractions of Ether as transaction fee (called 'gas'). This affects placing bets or claiming payouts, too. The fee amount is displayed by the transaction approval popup of Metamask. This is especially important if you plan to bet a small fraction of an Ether, because the transaction cost might outweight your bet earnings. 

Deployed smart contracts
------------------------
The UI is making the betting experience much better but in case you want want to interact manually with the bet smart contracts, here are the addresses of deployed smart contracts:

**Demo Bet**:

`0x1b9ea1b1825ea9956aec3de92a1cead55ce8b00b`

**Bets**:

`<coming soon>`

Future improvements
-------------------
* The external API that is fetched doesn't allow an efficient way to fetch the match result right now. Once the v2 of the API is released, there might be huge gas savings and a better UX. I have an implementation in mind to make fetching the match result much more flexible, fast and cheaper.
* Wanted to add more filters to the UI so you can narrow down the shown bets better. There will be 64 matches so scrolling through them will be a pain. I have to admit that my fronted/VueJS/Vuex skills are very limited, so not sure if this feature will make it in time.
