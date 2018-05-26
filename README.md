Ethercup
========

Bet with Ether on your favorite teams of the FIFA worldcup 2018 in Russia.

If you placed your bet(s) correctly, the collected Ether pool is split among you and other lucky users, who betted on the winning team. If you betted on the wrong team, you lose your Ether. In case of a draw between the two
teams, you get your Ether back.

The design of the deployed Bet smart contracts makes this betting dApp (distributed application) fraud- and tamper-proof! Your bets are safely stored in a smart contract, which will redistribute Ether when the winner is decided. In case something goes wrong (match postponed, external data provider misbehaves), you're always able to get all your Ether back without paying any fee! 

How it works
------------

For every match (bet), a smart contract is deployed on the Ethereum blockchain. Depending on the current stage of the bet, different interactions with the smart contracts are possible for any users, who installed the Metamask browser plugin. A bet goes through the following phases:

1. **Inactive**: The bet is deployed on the blockchain but it's too early to place bets.
2. **Open**: The bet opens 1 week before the match starts. You can bet on either team as often you want with as much Ether as you want.
3. **Closed/Match playing**: The bet closes 15 min before the match starts. It is too late to place bets now, as the match is starting soon.
4. **Match finished**: Around 90 min after match start, users can activate the smart contract so it starts fetching the match result from `football-data.org`. If there's no result yet after 90 min, e.g. because the match includes a penalty shootout at the end and it is just too early for a final match result, the smart contract will retry to fetch the final result every 1 hour. Once the final match result is fetched, the result has to be confirmed by the admin.
5. **Payouts**: Once the winner is fetched and confirmed, there's no go-back. The Ether pool is redistributed and a 1% fee is deducted. Users, who betted on the winning team, can claim their payouts. The bet cannot be cancelled anymore by anyone. But be careful: Your payouts expire after 1 month.

Each phase comes with a timeout. After this timeout, the next phase is entered, or, in case of a missing event in the previous phase (e.g. winner not confirmed), the smart contract switches to the final phase is 'cancelled'. A cancelled bet cannot be re-activated but anyone can get their Ether refunded.

Your bets are safe
------------------
The design of the smart contracts representing the various bets makes betting on Ethercup 100% fraud-proof. There are two outcomes of a bet:

1. The match is finished and the result is first correctly fetched and then confirmed. Subsequently, users can claim their payouts.
2. Something goes wrong, e.g. the match is postponed, the fetching does not return any match results or the result is not confirmed in time. In any of these cases, users get their bets fully refunded without paying any fee!

The owner/admin of the smart contracts is the only person, who can confirm the match result after it is fetched. This 2-phase approach is very secure: On the one hand you don't have to trust the external data provider, because in case he publishes wrong results, the owner of the smart contract disapproves the fetched match result. On the other hand you don't have to trust the owner, because he is only able to tell "yes, this match result is correct" or "no, this result is incorrect". After a single confirmation by the admin, we are either in payout phase (when the fetched winner is confirmed) or your bets are refunded to you (in case the confirmed winner doesn't match with the fetched winner). Win-win!

You can check the smart contract implementation yourself to decide if you want to trust this design.

Handling of special scenarios
-----------------------------
The tamper-proof nature of the Ethereum blockchain makes smart contracts the most trusted part of Ethercup. However, some aspects, i.e. fetching of the match result and confirmation by the admin, introduce human error and sources of potential failure.

Let's walk through these scenarios:
* *The external data provider doesn't deliver any data*:
	Fetching the match result is retried every 1 hour. In case the smart contract is unable to fetch the match result within 24h, the bet switches to "cancelled" and users can claim full refunds of their bets without paying any fee.
* *The external data provider is broken or even malicious and provides an incorrect match result*:
	The match result must be confirmed by the owner of the smart contract before payouts are possible. If the owner disapproves the fetched match result, the bet switches to "cancelled" and users can claim full refunds of their bets without paying any fee.
* *The owner (creator of this betting application) is malicious and wants to steal your funds*: Even if I were a scammer, I would not have the power (given the secure smart contract design) to steal a single penny from you. This is what I can do as owner/admin:
	* Bet on my favorite teams as anyone else can.
    * Confirm a winner: If I don't confirm a winner, the bet will switch to "cancelled" after a timeout of 1 day.
    * Cancel a bet: In case I haven't confirmed a fetched match result yet, I can cancel the bet at any previous stage. I will make use of this power when a match is postponed or any other bad event happens. If the bet is switched to "cancelled" you can claim full refunds of your bets without paying any fee.
    * Change the UI: I built the UI to let you interact with the bet smart contracts in a more convenient way. In case you don't trust the UI (source code is open sourced) and you still think that I could be a scammer, you don't have to use the UI. Feel free to call the smart contracts functions yourself, e.g. by using Ethereum's Mist browser. You can find the smart contract addresses at the bottom of every bet (in the UI) and at the end of this page.

Other things to note
--------------------
* Smart contracts can't be changed once they are deployed. In case of a postponed match for example, a new smart contract, which reflects a new match start time, will be deployed and replaces the old contract.
* Smart contracts don't execute code autonomously. This means that fetching of the match result as well as paying out lucky betters, doesn't happen automatically. Instead, you as a user have to call functions of the smart contract to start fetching or to claim payouts.
* Transactions on the Ethereum blockchain cost small fractions of Ether as fee (called 'gas'). This affects placing bets or claiming payouts, too. The fee amount is displayed by the transaction approval popup from Metamask. This is especially important if you plan to bet a small fraction of an Ether, because the transaction cost might outweight your bet earnings. 

Deployed smart contracts
------------------------
The UI is making the betting experience much better but in case you want want to interact manually with the bet smart contracts, here are the addresses of deployed smart contracts:

**Bet Registry** (contains the addresses of all bet smart contracts): `<coming soon>`
**Bets**:
`<coming soon>`

