TODO
[ ] staking contract
[ ] make sure ~21,000,000 get minted
[ ] tx.origin still?
[ ] swap/whatever function for `_accumulatedEth` lookup?
[ ] eth available function?
[ ] rename things to specifiy what is lottery and what is token things
[x] The lotto can be started by anyone but only one may run at the same time
[x] Interaction must not be through other smart contracts... no cheating!
    [x] start
    [x] buy tickets
    [x] payout function
[ ] Also should buffer time be lengthened/shortened/removed? What effect
    would it have on security?
[x] Need to include a reset function that deletes everything in order for
    the lotto to start over
    [n] Can i reset an entire map or make an array of maps and just set that
        array = []
[x] Need to add erc20 token
[ ] order functions
[X] payout function
[X] Need to add percentage fee for me to make money
[X] Need to add percentage fee for token holders to make money
[X] Clean up comments
[x] separate contract for people taking fees
    [x] erc20 token balance = % of the pot they can withdraw
    [x] if they hold the token
[x] make a public version of findTicketOwner - maybe on other file
[ ] maybe change `MINTER_ROLE` from public to private
[ ] figure out `DEFAULT_ADMIN_ROLE` - tx.origin?
[ ] just enabled minter only for transferWinnings- make sure it didn't break
[ ] `_beforeTokenTransfer` might not be needed anymore
[ ] only earn when staking? That way money on exchanges/MMs wont lose eth
[ ] commented a few things out hopefully they weren't needed