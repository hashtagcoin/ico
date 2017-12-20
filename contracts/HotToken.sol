pragma solidity ^0.4.11;
/**
 * This is the official Hot Token smart contract
 */
import "./lib/SafeMath.sol";
import "./lib/PausableToken.sol";

/**
 * @title HotToken
 */
contract HotToken is PausableToken {

  string public constant name = "HotToken";
  string public constant symbol = "HOT";
  uint public constant decimals = 18; // only two deciminals, token cannot be divided past 1/100th

  uint256 public constant INITIAL_SUPPLY = 125000000*(10**decimals); // 10 million + 2 decimals

  /**
   * @dev Contructor that gives msg.sender all of existing tokens.
   */
  function HotToken() public {
    totalSupply = INITIAL_SUPPLY;
    balances[msg.sender] = INITIAL_SUPPLY;
  }
}