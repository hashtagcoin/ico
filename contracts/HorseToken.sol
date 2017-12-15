pragma solidity ^0.4.13;

import 'zeppelin-solidity/contracts/token/MintableToken.sol';

contract HorseToken is MintableToken {
  string public name = "HORSE TOKEN";
  string public symbol = "HORSE";
  uint256 public decimals = 18;
}