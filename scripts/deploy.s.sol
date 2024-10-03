// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { Script } from "forge-std/Script.sol";
import { console } from "forge-std/console.sol";

import { Proxy } from "src/universal/Proxy.sol";
import { UniversalCharter } from "src/constitution/UniversalCharter.sol";
import { UniversalIdentity } from "src/constitution/UniversalIdentity.sol";
import { SystemConfig } from "src/constitution/SystemConfig.sol";

/// @title Deploy
/// @notice This script deploys the Points contract.
contract Deploy is Script {
    /// @notice The addresses of the contracts.
    mapping(string => address) public addresses;

    ////////////////////////////////////////////////////////////////
    //                        Modifiers                           //
    ////////////////////////////////////////////////////////////////

    /// @notice Modifier that wraps a function in broadcasting.
    modifier broadcast() {
        vm.startBroadcast(msg.sender);
        _;
        vm.stopBroadcast();
    }

    /// @notice Run the script
    function run() external {
        deployProxies();
        deployImplementations();
        setImplementation();
    }

    /// @notice Deploy Proxy
    function deployProxies() public {
        console.log("Deploying proxies");

        deployERC1967ProxyWithOwner("UniversalCharterProxy", msg.sender);
        deployERC1967ProxyWithOwner("UniversalIdentityProxy", msg.sender);
        deployERC1967ProxyWithOwner("SystemConfigProxy", msg.sender);
    }

    /// @notice Deploy implementations
    function deployImplementations() public broadcast {
        console.log("Deploying implementations");

        UniversalCharter universalCharter = new UniversalCharter();
        UniversalIdentity universalIdentity = new UniversalIdentity();
        SystemConfig systemConfig = new SystemConfig();

        addresses["UniversalCharter"] = address(universalCharter);
        addresses["UniversalIdentity"] = address(universalIdentity);
        addresses["SystemConfig"] = address(systemConfig);

        console.log("Deployed implementations");
    }

    /// @notice Set implementation
    function setImplementation() public broadcast {
        console.log("Setting implementation");

        UniversalCharter universalCharter = UniversalCharter(addresses["UniversalCharter"]);
        UniversalIdentity universalIdentity = UniversalIdentity(addresses["UniversalIdentity"]);
        SystemConfig systemConfig = SystemConfig(addresses["SystemConfig"]);

        Proxy universalCharterProxy = Proxy(payable(addresses["UniversalCharterProxy"]));
        Proxy universalIdentityProxy = Proxy(payable(addresses["UniversalIdentityProxy"]));
        Proxy systemConfigProxy = Proxy(payable(addresses["SystemConfigProxy"]));

        universalCharterProxy.upgradeTo(address(universalCharter));
        universalIdentityProxy.upgradeTo(address(universalIdentity));
        systemConfigProxy.upgradeTo(address(systemConfig));

        UniversalCharter universalCharterProxyContract = UniversalCharter(address(universalCharterProxy));
        UniversalIdentity universalIdentityProxyContract = UniversalIdentity(address(universalIdentityProxy));
        SystemConfig systemConfigProxyContract = SystemConfig(address(systemConfigProxy));

        universalCharterProxyContract.initialize(msg.sender, address(systemConfigProxyContract));
        universalIdentityProxyContract.initialize(msg.sender);
        systemConfigProxyContract.initialize(msg.sender);

        console.log("Set implementation");
    }

    /// @notice Deploy ERC1967 Proxy with owner
    /// @param _name The name of the proxy
    /// @param _proxyOwner The owner of the proxy
    function deployERC1967ProxyWithOwner(string memory _name, address _proxyOwner) public broadcast returns (address) {
        console.log("Deploying ERC1967 Proxy with owner: %s", _name);

        Proxy proxy = new Proxy({ _admin: _proxyOwner });

        console.log("Deployed ERC1967 Proxy with owner: %s", _name);

        addresses[_name] = address(proxy);

        return address(proxy);
    }
}
