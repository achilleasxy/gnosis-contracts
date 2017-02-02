pragma solidity ^0.4.0;
import "Tokens/StandardTokenWithOverflowProtection.sol";


/// @title Token contract - Token exchanging Ether 1:1.
/// @author Stefan George - <stefan.george@consensys.net>
contract EtherToken is StandardTokenWithOverflowProtection {

    /*
     *  Constants
     */
    // Token meta data
    string constant public name = "Ether Token";
    string constant public symbol = "ETH";
    uint8 constant public decimals = 18;

    /*
     *  Read and write functions
     */
    /// @dev Buys tokens with Ether, exchanging them 1:1.
    function deposit()
        external
        payable
    {
        if (   !safeToAdd(balances[msg.sender], msg.value)
            || !safeToAdd(totalSupply, msg.value))
        {
            // Overflow operation
            throw;
        }
        balances[msg.sender] += msg.value;
        totalSupply += msg.value;
    }

    /// @dev Sells tokens in exchange for Ether, exchanging them 1:1.
    /// @param amount Number of tokens to sell.
    function withdraw(uint amount)
        external
    {
        if (   !safeToSubtract(balances[msg.sender], amount)
            || !safeToSubtract(totalSupply, amount))
        {
            // Overflow operation
            throw;
        }
        balances[msg.sender] -= amount;
        totalSupply -= amount;
        if (!msg.sender.send(amount)) {
            // Sending failed
            throw;
        }
    }
}
