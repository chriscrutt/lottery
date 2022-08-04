TODO
- [ ] make it look pretty
- [ ] payout and restart 1 function
- [x] staking contract
- [x] make sure ~21,000,000 get minted
- [x] tx.origin still?
- [x] swap/whatever function for `_accumulatedEth` lookup?
- [x] eth available function?
- [ ] rename things to specifiy what is lottery and what is token things
- [x] The lotto can be started by anyone but only one may run at the same time
- [x] Interaction must not be through other smart contracts... no cheating!
  - [x] start
  - [x] buy tickets
  - [x] payout function
- [ ] Also should buffer time be lengthened/shortened/removed? What effect would it have on security?
- [x] Need to include a reset function that deletes everything in order for the lotto to start over
  - [x] Can i reset an entire map or make an array of maps and just set that array = [] (No sorry)
- [x] Need to add erc20 token
- [x] order functions
- [x] payout function
- [x] Need to add percentage fee for me to make money
- [X] Need to add percentage fee for token holders to make money
- [X] Clean up comments
- [x] separate contract for people taking fees
  - [x] erc20 token balance = % of the pot they can withdraw
  - [x] if they hold the token
- [x] make a public version of findTicketOwner - maybe on other file
- [ ] maybe change `MINTER_ROLE` from public to private
- [ ] figure out `DEFAULT_ADMIN_ROLE` - tx.origin?
- [x] just enabled minter only for transferWinnings- make sure it didn't break
- [x] `_beforeTokenTransfer` might not be needed anymore
- [x] only earn when staking? That way money on exchanges/MMs wont lose eth
- [x] commented a few things out hopefully they weren't needed```