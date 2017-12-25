pragma solidity ^0.4.18;


import "./Ownable.sol";
import './SafeMath.sol';

/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
  using SafeMath for uint256;

  event Pause();
  event Unpause();

  bool public paused = false;
  address public crowdsale;

  /*
  * @dev Freezing certain number of tokens bought during bonus.
  */
  mapping (address => uint256) public frozen;
  uint unfreezeTimestamp;

  function Pausable() {
    unfreezeTimestamp = now + 60 days; //default 60 days from contract deploy date as a defensive mechanism. Will be updated once the crowdsale starts.
  }

  function setUnfreezeTimestamp(uint _unfreezeTimestamp) onlyOwner {
    require(now < _frozenTimestamp);
  }

  function getFrozen(address _owner) view returns (uint256)  {
    return frozen[_owner];
  }

  function increaseFrozen(address _owner,uint _incrementalAmount) returns (uint256)  {
    require(msg.sender == crowdsale || msg.sender == owner);
    frozen[_owner] = frozen[_owner].add(_incrementalAmount);
  }

  function decreaseFrozen(address _owner,uint _incrementalAmount) returns (uint256)  {
    require(msg.sender == crowdsale || msg.sender == owner);
    frozen[_owner] = frozen[_owner].sub(_incrementalAmount);
  }
  
  function setCrowdsale(address _crowdsale) onlyOwner public {
      crowdsale=_crowdsale;
  }

  /**
   * @dev Modifier to make a function callable only when there are unfrozen tokens.
   */
  modifier frozenTransferCheck() {
    if (now < unfreezeTimestamp){
      require(_value <= balances[msg.sender].sub(frozen[msg.sender]) );
    }
    _;
  }

  modifier frozenTransferFromCheck() {
    require(now < unfreezeTimestamp);
    require(_value <= balances[_from].sub(frozen[_from]) );
    _;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is not paused.
   */
  modifier whenNotPaused() {
    require(!paused || msg.sender == crowdsale);
    _;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is paused.
   */
  modifier whenPaused() {
    require(paused);
    _;
  }

  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function pause() onlyOwner whenNotPaused public {
    require(msg.sender != address(0));
    paused = true;
    Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyOwner whenPaused public {
    require(msg.sender != address(0));
    paused = false;
    Unpause();
  }
}
