pragma solidity ^0.4.18;

import './StandardToken.sol';
import './Pausable.sol';
import './SafeMath.sol';

/**
 * @title Pausable token
 *
 * @dev StandardToken modified with pausable transfers.
 **/

contract PausableToken is StandardToken, Pausable {
  using SafeMath for uint256;
//  /*
//  * Freezing certain number of tokens bought during bonus.
//  */
//  mapping (address => uint256) public frozen;
//  address owner;
//  uint unfreezeTimestamp;
//
//
//  function PausableToken() {
//    owner = msg.sender;
//  }
//
//
//  function getFrozen(address _owner) view returns (uint256)  {
//    return frozen[_owner];
//  }
//
//  function increaseFrozen(address _owner) view returns (uint256)  {
//    return frozen[_owner];
//  }


  function transfer(address _to, uint256 _value) public whenNotPaused frozenTransferCheck(_to, _value, balances[msg.sender]) returns (bool) {
//    require(balances[msg.sender].sub());
    return super.transfer(_to, _value);
  }

  function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused frozenTransferFromCheck(_from, _to, _value, balances[_from]) returns (bool) {
    return super.transferFrom(_from, _to, _value);
  }

  function approve(address _spender, uint256 _value) public whenNotPaused returns (bool) {
    return super.approve(_spender, _value);
  }

  function increaseApproval(address _spender, uint _addedValue) public whenNotPaused returns (bool success) {
    return super.increaseApproval(_spender, _addedValue);
  }

  function decreaseApproval(address _spender, uint _subtractedValue) public whenNotPaused returns (bool success) {
    return super.decreaseApproval(_spender, _subtractedValue);
  }
}
