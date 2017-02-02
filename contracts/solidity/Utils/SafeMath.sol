pragma solidity ^0.4.0;


/// @title Safe math - Allows add and sub operations without overflow possibility.
contract SafeMath {

    /// @dev Returns if an add operation causes an overflow.
    /// @param a First addend.
    /// @param b Second addend.
    /// @return Did an overflow occur?
    function safeToAdd(uint a, uint b)
        internal
        returns (bool)
    {
        return (a + b >= a);
    }

    /// @dev Returns if an subtraction operation causes an overflow.
    /// @param a Minuend.
    /// @param b Subtrahend.
    /// @return Did an overflow occur?
    function safeToSubtract(uint a, uint b)
        internal
        returns (bool)
    {
        return (b <= a);
    }
}
