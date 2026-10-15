// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import { Test } from "forge-std/src/Test.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { AffixRegistry } from "../src/AffixRegistry.sol";

/**
 * @title AffixRegistryAgentTest
 * @notice Tests that addAgent requires and forwards the agent funding amount
 */
contract AffixRegistryAgentTest is Test {
    AffixRegistry public registry;

    address public owner = makeAddr("owner");
    address public agent = makeAddr("agent");
    address public user = makeAddr("user");

    uint256 constant AGENT_FUNDING = 0.000_001 ether;

    event AgentAdded(address indexed agent, address indexed addedBy);

    function setUp() public {
        registry = new AffixRegistry(owner, "Test University", "https://testuniversity.edu");
        vm.deal(owner, 1 ether);
        vm.deal(user, 1 ether);
    }

    function testAddAgentForwardsFunding() public {
        vm.expectEmit(true, true, false, false);
        emit AgentAdded(agent, owner);

        vm.prank(owner);
        registry.addAgent{ value: AGENT_FUNDING }(agent);

        assertTrue(registry.isAgent(agent));
        assertEq(agent.balance, AGENT_FUNDING);
        assertEq(address(registry).balance, 0);
    }

    function testAddAgentKeepsExcessInRegistry() public {
        vm.prank(owner);
        registry.addAgent{ value: 3 * AGENT_FUNDING }(agent);

        assertEq(agent.balance, AGENT_FUNDING);
        assertEq(address(registry).balance, 2 * AGENT_FUNDING);
    }

    function testAddAgentRevertsBelowFunding() public {
        vm.prank(owner);
        vm.expectRevert("Must send at least 0.000001 ETH");
        registry.addAgent{ value: AGENT_FUNDING - 1 }(agent);

        assertFalse(registry.isAgent(agent));
    }

    function testAddAgentRevertsWithoutValue() public {
        vm.prank(owner);
        vm.expectRevert("Must send at least 0.000001 ETH");
        registry.addAgent(agent);
    }

    function testOnlyOwnerCanAddAgent() public {
        vm.prank(user);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, user));
        registry.addAgent{ value: AGENT_FUNDING }(agent);
    }

    function testAddAgentRevertsWhenAgentRejectsEth() public {
        address rejecter = address(new EthRejecter());

        vm.prank(owner);
        vm.expectRevert("ETH transfer to agent failed");
        registry.addAgent{ value: AGENT_FUNDING }(rejecter);
    }
}

contract EthRejecter { }
