// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

/**
 * @title IAccessControlPlus interface
 *
 * @dev  This interface was implemeted based on the OpenZeppelin's 'IAccessControl'.
 *       ref: https://docs.openzeppelin.com/contracts/4.x/api/access#IAccessControl
 */
interface IAccessControlPlus {
    event AddedNewRole(
        string roleName,
        string adminRoleName,
        bytes32 roleId,
        bytes32 adminRoleId,
        address[] initialMembers
    );

    event RoleAdminChanged(bytes32 indexed roleId, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    event RoleGranted(bytes32 indexed roleId, address indexed account, address indexed from);

    event RoleRevoked(bytes32 indexed roleId, address indexed account, address indexed from);

    function hasRole(bytes32 roleId, address account) external view returns (bool);

    function getRoleAdmin(bytes32 roleId) external view returns (bytes32);

    function getRoleName(bytes32 roleId) external view returns (string memory);

    function getMemberCount() external view returns (uint256);

    // Returns the member count of the role
    function getRoleMemberCount(bytes32 role) external view returns (uint256);

    function addNewRole(
        string memory roleName,
        string memory adminRoleName,
        address[] memory initalAdminRoleMembers
    ) external;

    /**
     *  NOTE: We don't use the 'grantRole' function. Instead when an adminRole member mints a SBRT token
     *       or add a new reputation to other accounts, we will grant the role to the receiver by calling  '_grantRole'.
     */
    // function grantRole(bytes32 role, address account) external;

    function revokeRole(bytes32 role, address account) external;

    function revokeAllRoles(address member) external;
}
