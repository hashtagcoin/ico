pragma solidity ^0.4.11;
/**
 * This is the official Hot Token smart contract
 */
import "./lib/SafeMath.sol";
import "./lib/PausableToken.sol";

/**
 * @title MefyToken
 */
contract HorseToken is PausableToken {

    string public constant name = "Mefy";
    string public constant symbol = "MEFY";
    uint public constant decimals = 18;

    uint256 public constant INITIAL_SUPPLY = 125000000*(10**decimals); // 125 million x 18 decimals to represent in wei

    /**
     * @dev Contructor that gives msg.sender all of existing tokens.
     */
    function MefyToken() public {
        totalSupply = INITIAL_SUPPLY;
        balances[msg.sender] = INITIAL_SUPPLY;
        Transfer(0x0, msg.sender, INITIAL_SUPPLY);
    }
}
