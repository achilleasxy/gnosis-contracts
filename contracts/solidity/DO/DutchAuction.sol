pragma solidity 0.4.4;
import "Tokens/AbstractToken.sol";


/// @title Dutch auction contract - creation of Gnosis tokens.
/// @author Stefan George - <stefan.george@consensys.net>
contract DutchAuction {

    /*
     *  Events
     */
    event BidSubmission(address indexed sender, uint256 amount);

    /*
     *  Constants
     */
    uint constant public CEILING = 1500000 ether;
    uint constant public TOTAL_TOKENS = 10000000; // 10M
    uint constant public MAX_TOKENS_SOLD = 9000000; // 9M
    uint constant public WAITING_PERIOD = 7 days;

    /*
     *  Storage
     */
    Token public gnosisToken;
    address public wallet;
    address public owner;
    uint public startBlock;
    uint public endTime;
    uint public totalReceived;
    uint public finalPrice;
    mapping (address => uint) public bids;
    Stages public stage = Stages.AuctionStarted;

    /*
     *  Enums
     */
    enum Stages {
        AuctionStarted,
        AuctionEnded
    }

    /*
     *  Modifiers
     */
    modifier atStage(Stages _stage) {
        if (stage != _stage) {
            // Contract not in expected state
            throw;
        }
        _;
    }

    modifier isOwner() {
        if (msg.sender != owner) {
            // Only owner is allowed to proceed
            throw;
        }
        _;
    }

    modifier timedTransitions() {
        if (stage == Stages.AuctionStarted && calcTokenPrice() <= calcStopPrice()) {
            finalizeAuction();
        }
        _;
    }

    /*
     *  Public functions
     */
    /// @dev Contract constructor function sets start date.
    function DutchAuction()
        public
    {
        startBlock = block.number;
        owner = msg.sender;
    }

    /// @dev Setup function sets external contracts' addresses.
    /// @param _gnosisToken Gnosis token address.
    /// @param _wallet Gnosis founders address.
    function setup(address _gnosisToken, address _wallet)
        public
        isOwner
    {
        if (wallet != 0 || address(gnosisToken) != 0) {
            // Setup was executed already
            throw;
        }
        wallet = _wallet;
        gnosisToken = Token(_gnosisToken);
    }

    /// @dev Returns if one week after auction passed.
    /// @return Returns if one week after auction passed.
    function tokenLaunched()
        public
        timedTransitions
        returns (bool)
    {
        return block.timestamp > endTime + WAITING_PERIOD;
    }

    /// @dev Returns correct stage, even if a function with timedTransitions modifier has not yet been called yet.
    /// @return Returns current auction stage.
    function updateStage()
        public
        timedTransitions
        returns (Stages)
    {
        return stage;
    }

    /// @dev Calculates current token price.
    /// @return Returns token price.
    function calcCurrentTokenPrice()
        public
        timedTransitions
        returns (uint)
    {
        if (stage == Stages.AuctionEnded) {
            return finalPrice;
        }
        return calcTokenPrice();
    }

    /// @dev Allows to send a bid to the auction.
    function bid(address receiver)
        public
        payable
        timedTransitions
        atStage(Stages.AuctionStarted)
    {
        if (receiver == 0) {
            receiver = msg.sender;
        }
        uint amount = msg.value;
        if (totalReceived + amount > CEILING) {
            amount = CEILING - totalReceived;
            // Send change back
            if (!receiver.send(msg.value - amount)) {
                // Sending failed
                throw;
            }
        }
        // Forward funding to ether wallet
        if (amount == 0 || !wallet.send(amount)) {
            // No amount sent or sending failed
            throw;
        }
        bids[receiver] += amount;
        totalReceived += amount;
        if (totalReceived == CEILING) {
            finalizeAuction();
        }
        BidSubmission(receiver, amount);
    }

    /// @dev Claims tokens for bidder after auction.
    function claimTokens(address receiver)
        public
        timedTransitions
        atStage(Stages.AuctionEnded)
    {
        if (receiver == 0) {
            receiver = msg.sender;
        }
        uint tokenCount = bids[receiver] * 10**18 / finalPrice;
        bids[receiver] = 0;
        gnosisToken.transfer(receiver, tokenCount);
    }

    /// @dev Calculates stop price.
    /// @return Returns stop price.
    function calcStopPrice()
        constant
        public
        returns (uint)
    {
        return totalReceived / MAX_TOKENS_SOLD;
    }

    /// @dev Calculates token price.
    /// @return Returns token price.
    function calcTokenPrice()
        constant
        public
        returns (uint)
    {
        return 20000 * 1 ether / (block.number - startBlock + 7500);
    }

    /*
     *  Private functions
     */
    function finalizeAuction()
        private
    {
        stage = Stages.AuctionEnded;
        if (totalReceived == CEILING) {
            finalPrice = calcTokenPrice();
        }
        else {
            finalPrice = calcStopPrice();
        }
        uint soldTokens = totalReceived * 10**18 / finalPrice;
        // Auction contract transfers all unsold tokens to Gnosis inventory multisig
        gnosisToken.transfer(wallet, TOTAL_TOKENS * 10**18 - soldTokens);
        endTime = block.timestamp;
    }
}
