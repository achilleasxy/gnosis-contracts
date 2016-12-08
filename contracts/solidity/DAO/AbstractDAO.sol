/// @title Abstract DAO contract - Functions to be implemented by DAO contracts.
contract DAO {
    function calcBaseFee(address sender, address token, uint tokenCount) returns (uint fee);
    function calcBaseFeeForShares(address sender, address token, uint shareCount) returns (uint fee);
}
