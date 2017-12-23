pragma solidity ^0.4.18;
import "./lib/Ownable.sol";
import "./lib/SafeMath.sol";
// import "./lib/PausableToken.sol";
// **-----------------------------------------------
// EthBet.io Token sale contract
// Final revision 16a
// Refunds integrated, full test suite passed
// **-----------------------------------------------
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/issues/20
// -------------------------------------------------
// Price configuration:
// First Day Bonus    +50% = 1,500 HOT  = 1 ETH       [blocks: start   -> s+3600]
// First Week Bonus   +40% = 1,400 HOT  = 1 ETH       [blocks: s+3601  -> s+25200]
// Second Week Bonus  +30% = 1,300 HOT  = 1 ETH       [blocks: s+25201 -> s+50400]
// Third Week Bonus   +25% = 1,250 HOT  = 1 ETH       [blocks: s+50401 -> s+75600]
// Final Week Bonus   +15% = 1,150 HOT  = 1 ETH       [blocks: s+75601 -> end]
// -------------------------------------------------

contract PausableToken is Ownable {
  using SafeMath for uint256;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract HotCrowdsale is Ownable {
  using SafeMath for uint256;
  PausableToken  public tokenReward;                         // address of the token used as reward

  // deployment variables for static supply sale
  uint256 public initialSupply;
  uint256 public tokensRemaining;
  uint256 public decimals;

  // multi-sig addresses and price variable
  address public beneficiaryWallet;                           // beneficiaryMultiSig (founder group) or wallet account, live is 0x00F959866E977698D14a36eB332686304a4d6AbA
  uint256 public tokensPerEthPrice;                           // set initial value floating priceVar 1,500 tokens per Eth

  // uint256 values for min,max,caps,tracking
  uint256 public amountRaisedInWei;                           //
  uint256 public fundingMinCapInWei;                          //

  // loop control, ICO startup and limiters
  string  public CurrentStatus                   = "";        // current crowdsale status
  uint256 public fundingStartTime;                           // crowdsale start block#
  uint256 public fundingEndTime;                             // crowdsale end block#
  bool    public isCrowdSaleClosed               = false;     // crowdsale completion boolean
  bool    public areFundsReleasedToBeneficiary   = false;     // boolean for founder to receive Eth or not
  bool    public isCrowdSaleSetup                = false;     // boolean for crowdsale setup

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
  event Buy(address indexed _sender, uint256 _eth, uint256 _HOT);
  event Refund(address indexed _refunder, uint256 _value);
  event Burn(address _from, uint256 _value);
  mapping(address => uint256) balancesArray;
  mapping(address => uint256) fundValue;

  // default function, map admin
  function HotTokenCrowdsale() onlyOwner public {
    CurrentStatus = "Crowdsale deployed to chain";
  }
  
  // convert tokens to decimals
  function toPony(uint256 amount) public constant returns (uint256) {
      return amount.mul(10**decimals);
  }
  
  // convert tokens to whole
  function toHot(uint256 amount) public constant returns (uint256) {
      return amount.div(10**decimals);
  }

  // total number of tokens initially
  function initialHOTSupply() public constant returns (uint256 tokenTotalSupply) {
      tokenTotalSupply = initialSupply.div(100);
  }

  // remaining number of tokens
  function remainingSupply() public constant returns (uint256 tokensLeft) {
      tokensLeft = tokensRemaining;
  }

  // setup the CrowdSale parameters
  function setupCrowdsale(uint256 _fundingStartTime, uint256 _fundingEndTime) public onlyOwner returns (bytes32 response) {
      if ((!(isCrowdSaleSetup))
      && (!(beneficiaryWallet > 0))){
          // init addresses
          tokenReward                             = PausableToken(0x127db7c9D848DbDB1635861Af233012f7BaEcAAe);  // Ropsten: 0xec155d80c7400484fb2d3732fa2aa779348f52e4 Kovan: 0xc35e495b3de0182DB3126e74b584B745839692aB
          beneficiaryWallet                       = 0xafE0e12d44486365e75708818dcA5558d29beA7D;   // mainnet is 0x00F959866E977698D14a36eB332686304a4d6AbA //testnet = 0xDe6BE2434E8eD8F74C8392A9eB6B6F7D63DDd3D7
          tokensPerEthPrice                       = toPony(20000);                                         // set day1 initial value floating priceVar 1,500 tokens per Eth

          // funding targets
          fundingMinCapInWei                      = 1 ether;                          //500 Eth (min cap) - crowdsale is considered success after this value

          // update values
          decimals                                = 18;
          amountRaisedInWei                       = 0;
          initialSupply                           = toPony(100000000);                  //   100 million * 18 decimal = 1000000000
          tokensRemaining                         = initialSupply;

          fundingStartTime                       = _fundingStartTime;
          fundingEndTime                         = _fundingEndTime;

          // configure crowdsale
          isCrowdSaleSetup                        = true;
          isCrowdSaleClosed                       = false;
          CurrentStatus                           = "Crowdsale is setup";

          //gas reduction experiment
          setPrice();
          return "Crowdsale is setup";
      } else if (msg.sender != owner) {
          return "not authorized";
      } else  {
          return "campaign cannot be changed";
      }
    }

    function setPrice() public {
      // Price configuration:
      // First Day Bonus    +50% = 1,500 HOT  = 1 ETH       [blocks: start -> s+3600]
      // First Week Bonus   +40% = 1,400 HOT  = 1 ETH       [blocks: s+3601  -> s+25200]
      // Second Week Bonus  +30% = 1,300 HOT  = 1 ETH       [blocks: s+25201 -> s+50400]
      // Third Week Bonus   +25% = 1,250 HOT  = 1 ETH       [blocks: s+50401 -> s+75600]
      // Final Week Bonus   +15% = 1,150 HOT  = 1 ETH       [blocks: s+75601 -> endblock]
      if (block.timestamp >= fundingStartTime && block.timestamp < fundingStartTime + 5 minutes) { // First Day Bonus    +50% = 1,500 HOT  = 1 ETH  [blocks: start -> s+24]
        tokensPerEthPrice=toPony(20000);
      } else if (block.timestamp >= fundingStartTime+5 minutes && block.timestamp < fundingStartTime+10 minutes) { // First Week Bonus   +40% = 1,400 HOT  = 1 ETH  [blocks: s+25 -> s+45]
        tokensPerEthPrice=toPony(10000);
      } else if (block.timestamp >= fundingStartTime+10 minutes && block.timestamp < fundingStartTime+15 minutes) { // Second Week Bonus  +30% = 1,300 HOT  = 1 ETH  [blocks: s+46 -> s+65]
        tokensPerEthPrice=toPony(5000);
      } else if (block.timestamp >= fundingStartTime+15 minutes && block.timestamp < fundingStartTime+20 minutes) { // Third Week Bonus   +25% = 1,250 HOT  = 1 ETH  [blocks: s+66 -> s+85]
        tokensPerEthPrice=toPony(1250);
      } else if (block.timestamp >= fundingStartTime+20 minutes && block.timestamp <=fundingEndTime) { // Final Week Bonus   +15% = 1,150 HOT  = 1 ETH  [blocks: s+86 -> endBlock]
        tokensPerEthPrice=toPony(1150);
      }
    }

    // default payable function when sending ether to this contract
    function () public payable {
      require(msg.data.length == 0);
      BuyHOTtokens();
    }

    function getBlockNumber() public constant returns (uint) {
        return block.timestamp;
    }

    function BuyHOTtokens() public payable {
      // 0. conditions (length, crowdsale setup, zero check, exceed funding contrib check, contract valid check, within funding block range check, balance overflow check etc)
      require(!(msg.value == 0)
      && (isCrowdSaleSetup)
      && (block.timestamp >= fundingStartTime)
      && (block.timestamp <= fundingEndTime)
      && (tokensRemaining > 0));

      // 1. vars
      uint256 rewardTransferAmount    = 0;

      // 2. effects
      setPrice();
      amountRaisedInWei               = amountRaisedInWei.add(msg.value);
      rewardTransferAmount            = (msg.value.mul(tokensPerEthPrice)).div(10**18); //

      // 3. interaction
      tokensRemaining                 = tokensRemaining.sub(rewardTransferAmount);  // will cause throw if attempt to purchase over the token limit in one tx or at all once limit reached
      tokenReward.transfer(msg.sender, rewardTransferAmount);

      // 4. events
      fundValue[msg.sender]           = fundValue[msg.sender].add(msg.value);
      Transfer(this, msg.sender, msg.value);
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
        CurrentStatus = "In progress (Eth < Softcap)";
        return "In progress (Eth < Softcap)";
      } else if ((amountRaisedInWei < fundingMinCapInWei) && (block.timestamp < fundingStartTime)) { // ICO has not started
        areFundsReleasedToBeneficiary = false;
        isCrowdSaleClosed = false;
        CurrentStatus = "Crowdsale is setup";
        return "Crowdsale is setup";
      } else if ((amountRaisedInWei < fundingMinCapInWei) && (block.timestamp > fundingEndTime)) { // ICO ended, under softcap
        areFundsReleasedToBeneficiary = false;
        isCrowdSaleClosed = true;
        CurrentStatus = "Unsuccessful (Eth < Softcap)";
        return "Unsuccessful (Eth < Softcap)";
      } else if ((amountRaisedInWei >= fundingMinCapInWei) && (tokensRemaining == 0)) { // ICO ended, all tokens gone
          areFundsReleasedToBeneficiary = true;
          isCrowdSaleClosed = true;
          CurrentStatus = "Successful (HOT >= Hardcap)!";
          return "Successful (HOT >= Hardcap)!";
      } else if ((amountRaisedInWei >= fundingMinCapInWei) && (block.timestamp > fundingEndTime) && (tokensRemaining > 0)) { // ICO ended, over softcap!
          areFundsReleasedToBeneficiary = true;
          isCrowdSaleClosed = true;
          CurrentStatus = "Successful (Eth >= Softcap)!";
          return "Successful (Eth >= Softcap)!";
      } else if ((amountRaisedInWei >= fundingMinCapInWei) && (tokensRemaining > 0) && (block.timestamp <= fundingEndTime)) { // ICO in progress, over softcap!
        areFundsReleasedToBeneficiary = true;
        isCrowdSaleClosed = false;
        CurrentStatus = "In progress (Eth >= Softcap)!";
        return "In progress (Eth >= Softcap)!";
      }
      setPrice();
    }

    function refund() public { // any contributor can call this to have their Eth returned. user's purchased HOT tokens are burned prior refund of Eth.
      //require minCap not reached
      
      require ((amountRaisedInWei < fundingMinCapInWei)
      && (isCrowdSaleClosed)
      && (block.timestamp > fundingEndTime)
      && (fundValue[msg.sender] > 0));

      //burn user's token HOT token balance, refund Eth sent
      uint256 ethRefund = fundValue[msg.sender];
      balancesArray[msg.sender] = 0;
      fundValue[msg.sender] = 0;
      Burn(msg.sender, ethRefund);

      //send Eth back, burn tokens
      msg.sender.transfer(ethRefund);
      Refund(msg.sender, ethRefund);
    }
    
    function revertToOwner() public onlyOwner {
        tokenReward.transfer(msg.sender, tokensRemaining);
    }
}