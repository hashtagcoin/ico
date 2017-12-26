pragma solidity ^0.4.18;
import "./lib/Ownable.sol";
import "./lib/SafeMath.sol";

// **-----------------------------------------------
// HORSE Token sale contract
// **-----------------------------------------------
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/issues/20
// -------------------------------------------------
// Price configuration:
// First Day Bonus    +50% = 1,500 HORSE  = 1 ETH       [blocks: start   -> s+3600]
// First Week Bonus   +40% = 1,400 HORSE  = 1 ETH       [blocks: s+3601  -> s+25200]
// Second Week Bonus  +30% = 1,300 HORSE  = 1 ETH       [blocks: s+25201 -> s+50400]
// Third Week Bonus   +25% = 1,250 HORSE  = 1 ETH       [blocks: s+50401 -> s+75600]
// Final Week Bonus   +15% = 1,150 HORSE  = 1 ETH       [blocks: s+75601 -> end]
// -------------------------------------------------

contract PausableToken is Ownable {
    function balanceOf(address who) public constant returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    function increaseFrozen(address _owner,uint256 _incrementalAmount) public returns (bool);
}

contract HorseTokenCrowdsale is Ownable {
    using SafeMath for uint256;
    PausableToken  public tokenReward;                         // address of the token used as reward

    // deployment variables for static supply sale
    uint256 public initialSupply;
    uint256 public tokensRemaining;
    uint256 public decimals;

    // multi-sig addresses and price variable
    address public beneficiaryWallet;                           // beneficiaryMultiSig (founder group) or wallet account
    uint256 public tokensPerEthPrice;                           // set initial value floating priceVar 10,000 tokens per Eth

    // uint256 values for min,max,caps,tracking
    uint256 public amountRaisedInWei;
    uint256 public fundingMinCapInWei;

    // pricing veriable
    uint256 public p1_duration;
    uint256 public p2_start;
    
    //TODO: remove the following lines
    //test varibles
    // uint256 public rewardTransferAmount;
    // uint256 public rewardBonusTransferAmount;


    // loop control, ICO startup and limiters
    uint256 public fundingStartTime;                           // crowdsale start time#
    uint256 public fundingEndTime;                             // crowdsale end time#
    bool    public isCrowdSaleClosed               = false;     // crowdsale completion boolean
    bool    public areFundsReleasedToBeneficiary   = false;     // boolean for founder to receive Eth or not
    bool    public isCrowdSaleSetup                = false;     // boolean for crowdsale setup

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Buy(address indexed _sender, uint256 _eth, uint256 _HORSE);
    event Refund(address indexed _refunder, uint256 _value);
    event Burn(address _from, uint256 _value);
    mapping(address => uint256) fundValue;


    // convert tokens to decimals
    function toPony(uint256 amount) public constant returns (uint256) {
        return amount.mul(10**decimals);
    }

    // convert tokens to whole
    function toHorse(uint256 amount) public constant returns (uint256) {
        return amount.div(10**decimals);
    }

    // total number of tokens initially
    function initialHORSESupply() public constant returns (uint256 tokenTotalSupply) {
        tokenTotalSupply = toHorse(initialSupply);
    }

    // remaining number of tokens
    function remainingSupply() public constant returns (uint256 tokensLeft) {
        tokensLeft = tokensRemaining;
    }

    function increaseFrozen(address _ownerLocal, uint256 _incrementLocal) public {
        tokenReward.increaseFrozen(_ownerLocal, _incrementLocal);
    }

    // setup the CrowdSale parameters
    function setupCrowdsale(uint256 _fundingStartTime) public onlyOwner returns (bytes32 response) {
        if ((!(isCrowdSaleSetup))
            && (!(beneficiaryWallet > 0))){
            // init addresses
            tokenReward                             = PausableToken(0x119686eF59F6c512ec47aC2E3957a4f742ad0043);  // Ropsten: 0xec155d80c7400484fb2d3732fa2aa779348f52e4 Kovan: 0xc35e495b3de0182DB3126e74b584B745839692aB
            beneficiaryWallet                       = 0xafE0e12d44486365e75708818dcA5558d29beA7D;   // mainnet is 0x00F959866E977698D14a36eB332686304a4d6AbA //testnet = 0xDe6BE2434E8eD8F74C8392A9eB6B6F7D63DDd3D7
            // tokensPerEthPrice                       = toPony(10000);                                         // Base price 10000 tokens per Eth
            tokensPerEthPrice                       = 10000;                                         // testnet

            // funding targets
            fundingMinCapInWei                      = 1 ether;                          //500 Eth (min cap) - crowdsale is considered success after this value

            // update values
            decimals                                = 18;
            amountRaisedInWei                       = 0;
            initialSupply                           = toPony(100000000);                  //   100 million * 18 decimal
            tokensRemaining                         = initialSupply;

            fundingStartTime                        = _fundingStartTime;
            // p1_duration                             = 7 days;
            p1_duration                             = 7 minutes; //testnet
            // p2_start                                = fundingStartTime + p1_duration + 6 days;
            p2_start                                = fundingStartTime + p1_duration + 6 minutes;
            // fundingEndTime                          = p2_start + 4 weeks;
            fundingEndTime                          = p2_start + 4 hours;

            // configure crowdsale
            isCrowdSaleSetup                        = true;
            isCrowdSaleClosed                       = false;

            return "Crowdsale is setup";
        }
    }

    function setBonusPrice() public constant returns (uint256 bonus) {
        require(isCrowdSaleSetup && fundingStartTime + p1_duration < p2_start );
        if (now >= fundingStartTime && now <= fundingStartTime + p1_duration) { // Phase-1 Bonus    +100% = 20,000 HORSE  = 1 ETH
            // bonus = toPony(10000);
            bonus = 10000;
        } else if (now > p2_start && now <= p2_start + 1 days ) { // Phase-2 day-1 Bonus +50% = 15,000 HORSE = 1 ETH
            // bonus = toPony(5000);
            bonus = 5000;
        } else if (now > p2_start + 1 days && now <= p2_start + 1 weeks - 1 days) { // Phase-2 week-1 Bonus +20% = 12,000 HORSE = 1 ETH
            // bonus = toPony(2000);
            bonus = 2000;
        } else if (now > p2_start + 1 weeks && now <= p2_start + 2 weeks ) { // Phase-2 week-2 Bonus +10% = 11,000 HORSE = 1 ETH
            // bonus = toPony(1000);
            bonus = 1000;
        } else if (now > p2_start + 2 weeks && now <= fundingEndTime ) { // Phase-2 week-3& week-4 Bonus +0% = 10,000 HORSE = 1 ETH
            bonus = 0;
        } else {
            revert();
        }
    }

    // default payable function when sending ether to this contract
    function () public payable {
        require(msg.data.length == 0);
        BuyHORSEtokens();
    }

    function getBlockNumber() public constant returns (uint) {
        return block.timestamp;
    }

    function updateDuration(uint256 _newP1Duration, uint256 _newP2Start) public onlyOwner{ // function to update the duration of phase-1 and adjust the start time of phase-2
        require( isCrowdSaleSetup
            && !((p1_duration == _newP1Duration) && (p2_start == _newP2Start)) 
            && (now < fundingStartTime + p1_duration) 
            && (now < fundingStartTime + _newP1Duration)
            && (fundingStartTime + _newP1Duration < _newP2Start));
        p1_duration = _newP1Duration;
        p2_start = _newP2Start;
        fundingEndTime = p2_start + 4 weeks;
    }

    function BuyHORSEtokens() public payable {
        // 0. conditions (length, crowdsale setup, zero check, exceed funding contrib check, contract valid check, within funding block range check, balance overflow check etc)
        require(!(msg.value == 0)
        && (isCrowdSaleSetup)
        && (block.timestamp >= fundingStartTime)
        && (block.timestamp <= fundingEndTime)
        && (tokensRemaining > 0));

        // 1. vars
        uint256 rewardTransferAmount    = 0;
        uint256 rewardBonusTransferAmount =0;

        // 2. effects
        rewardBonusTransferAmount = setBonusPrice();
        amountRaisedInWei               = amountRaisedInWei.add(msg.value);
        rewardTransferAmount            = (msg.value.mul(tokensPerEthPrice));//.div(10**18);
        rewardBonusTransferAmount       = (msg.value.mul(rewardBonusTransferAmount));//.div(10**18);

        // 3. interaction
        rewardTransferAmount            = rewardTransferAmount.add(rewardBonusTransferAmount);
        tokensRemaining                 = tokensRemaining.sub(rewardTransferAmount);  // will cause throw if attempt to purchase over the token limit in one tx or at all once limit reached
        tokenReward.transfer(msg.sender, rewardTransferAmount);
        assert(tokenReward.increaseFrozen(msg.sender, rewardBonusTransferAmount));

        // 4. events
        fundValue[msg.sender]           = fundValue[msg.sender].add(msg.value);
        //      Transfer(this, msg.sender, msg.value);
        Buy(msg.sender, msg.value, rewardTransferAmount);
    }

    function beneficiaryMultiSigWithdraw(uint256 _amount) public onlyOwner {
        checkGoalReached();
        require(areFundsReleasedToBeneficiary && (amountRaisedInWei >= fundingMinCapInWei));
        beneficiaryWallet.transfer(_amount);
    }

    function checkGoalReached() public onlyOwner returns (bytes32 response) { // return crowdfund status to owner for each result case, update public constant
        // update state & status variables
        require (isCrowdSaleSetup);
        if ((amountRaisedInWei < fundingMinCapInWei) && (block.timestamp <= fundingEndTime && block.timestamp >= fundingStartTime)) { // ICO in progress, under softcap
            areFundsReleasedToBeneficiary = false;
            isCrowdSaleClosed = false;
            return "In progress (Eth < Softcap)";
        } else if ((amountRaisedInWei < fundingMinCapInWei) && (block.timestamp < fundingStartTime)) { // ICO has not started
            areFundsReleasedToBeneficiary = false;
            isCrowdSaleClosed = false;
            return "Crowdsale is setup";
        } else if ((amountRaisedInWei < fundingMinCapInWei) && (block.timestamp > fundingEndTime)) { // ICO ended, under softcap
            areFundsReleasedToBeneficiary = false;
            isCrowdSaleClosed = true;
            return "Unsuccessful (Eth < Softcap)";
        } else if ((amountRaisedInWei >= fundingMinCapInWei) && (tokensRemaining == 0)) { // ICO ended, all tokens gone
            areFundsReleasedToBeneficiary = true;
            isCrowdSaleClosed = true;
            return "Successful (HORSE >= Hardcap)!";
        } else if ((amountRaisedInWei >= fundingMinCapInWei) && (block.timestamp > fundingEndTime) && (tokensRemaining > 0)) { // ICO ended, over softcap!
            areFundsReleasedToBeneficiary = true;
            isCrowdSaleClosed = true;
            return "Successful (Eth >= Softcap)!";
        } else if ((amountRaisedInWei >= fundingMinCapInWei) && (tokensRemaining > 0) && (block.timestamp <= fundingEndTime)) { // ICO in progress, over softcap!
            areFundsReleasedToBeneficiary = true;
            isCrowdSaleClosed = false;
            return "In progress (Eth >= Softcap)!";
        }
    }

    function refund() public { // any contributor can call this to have their Eth returned. user's purchased HORSE tokens are burned prior refund of Eth.
        //require minCap not reached
        checkGoalReached();
        require ((amountRaisedInWei < fundingMinCapInWei)
        && (isCrowdSaleClosed)
        && (now > fundingEndTime)
        && (fundValue[msg.sender] > 0));

        //burn user's token HORSE token balance, refund Eth sent
        uint256 ethRefund = fundValue[msg.sender];
        fundValue[msg.sender] = 0;
        Burn(msg.sender, ethRefund);

        //send Eth back, burn tokens
        msg.sender.transfer(ethRefund);
        Refund(msg.sender, ethRefund);
    }
}