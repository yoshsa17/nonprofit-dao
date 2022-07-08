// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

import "../interfaces/IAccessControlPlus.sol";

/**
 * @title Access Control control
 *
 * @dev  This contract was implemeted based on the OpenZeppelin's AccessControl contract.
 *       We added some simple extensions and modified the behavior of it.
 *       ref: https://docs.openzeppelin.com/contracts/4.x/api/access#AccessControl

 * Role structure example:
 * NOTE: Only member1 and member2 can grant FRONTEND_DEV role by minting a SBRT or adding reputations for other members.
 * 
 *              RoleName |   AdominRole   | Memebers
 *              ---------|----------------|--------
 *              GOVERNOR | GOERNOR        | GovrenorAddress
 *          FRONTEND_DEV | FRONTEND_DEV_HR| member1, member2, member3,
 *       FRONTEND_DEV_HR | 0X00           | member1, member2   
 */
contract AccessControlPlus is Context, IAccessControlPlus {
    using Counters for Counters.Counter;

    bytes32 public constant GOVERNOR = keccak256("GOVERNOR");

    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
        string name;
        Counters.Counter memberCount;
    }

    // Mapping of roleId to its data
    mapping(bytes32 => RoleData) private _roles;
    // Mapping of member to roleId list
    mapping(address => string[]) private _grantedRoles;

    // Member counter
    Counters.Counter private _memberCount;

    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    // -------------------------------------------------------------------------
    // Static functions
    // -------------------------------------------------------------------------

    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    // Returns the roleId list of the member
    function getGrantedRoles(address account) public view virtual returns (string[] memory) {
        return _grantedRoles[account];
    }

    // Returns the role name of the roleId
    function getRoleName(bytes32 roleId) public view returns (string memory) {
        return _roles[roleId].name;
    }

    // Returns the role count of the member
    function getMemberRoleCount(address member) public view returns (uint256) {
        return _grantedRoles[member].length;
    }

    // Returns true if the role exists
    function roleExists(bytes32 role) public view returns (bool) {
        return bytes(_roles[role].name).length != 0;
    }

    // Return the number of total members
    function getMemberCount() public view returns (uint256) {
        return _memberCount.current();
    }

    // Returns the member count of the role
    function getRoleMemberCount(bytes32 role) public view returns (uint256) {
        return _roles[role].memberCount.current();
    }

    // -------------------------------------------------------------------------
    // External functions
    // -------------------------------------------------------------------------

    /**
     * @dev Initializes an new role in '_roles'
     *      When a role is newly added, this should be called by Govrenor contract
     */
    function addNewRole(
        string memory roleName,
        string memory adminRoleName,
        address[] memory initialMembers
    ) external onlyRole(GOVERNOR) {
        _addNewRole(roleName, adminRoleName, initialMembers);
    }

    /**
     * @dev Revokes a role from a member
     *      Only governor can revoke a role, insted of the adminRole members.
     */
    function revokeRole(bytes32 role, address member) public virtual override onlyRole(GOVERNOR) {
        _revokeRole(role, member);
    }

    /**
     * @dev Revokes all roles from a member
     */
    function revokeAllRoles(address member) external onlyRole(GOVERNOR) {
        _revokeAllRoles(member);
    }

    // -------------------------------------------------------------------------
    // Internal functions
    // -------------------------------------------------------------------------

    /**
     * @dev Adds a new role to '_roles'
     */
    function _addNewRole(
        string memory roleName,
        string memory adminRoleName,
        address[] memory initalAdminRoleMembers
    ) internal virtual {}

    function _setRoleName(bytes32 roleId, string memory roleName) internal {
        _roles[roleId].name = roleName;
    }

    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Adds a address to '_role'
     *      This function is intended to be used to set unique roles like governor role.
     */
    function _setUp(bytes32 role, address account) internal virtual {
        _roles[role].members[account] = true;
    }

    /**
     * @dev Adds an account to '_role' and adds the given role to member's role list
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            // _roles
            _roles[role].members[account] = true;
            _roles[role].memberCount.increment();
            emit RoleGranted(role, account, _msgSender());
            // _grantedRoles
            _grantedRoles[account].push(getRoleName(role));
            // _memberCount
            _memberCount.increment();
        }
    }

    /**
     * @dev Revokes an account from '_role' and removes a roleId from member's role list
     * TODO: this function is not implemented yet.
     */
    function _revokeRole(bytes32 role, address member) internal virtual {
        // _roles
        // TODO: decrement the number of the member count
        // if (hasRole(role, member)) {
        //     _roles[role].members[member] = false;
        //     emit RoleRevoked(role, member, _msgSender());
        // }
        // // _grantedRoles
        // uint256 length = _grantedRoles[member].length;
        // // TODO:: refactor this to use a for loop
        // for (uint256 index = 0; index < length; index++) {
        //     if (_grantedRoles[member][index] == getRoleName(role)) {
        //         _grantedRoles[member][index] = _grantedRoles[member][length - 1];
        //         _grantedRoles[member].pop();
        //         break;
        //     }
        // }
    }

    /**
     * @dev Revoke all roles from a member
     * TODO: this function is not implemented yet.
     */
    function _revokeAllRoles(address member) internal {
        // // revoke roles from _roles
        // uint256 length = _grantedRoles[member].length;
        // emit debug(length, member);
        // for (uint256 i = 0; i < length; i++) {
        //     bytes32 role = _grantedRoles[member][i];
        //     _roles[role].members[member] = false;
        //     emit RoleRevoked(role, member, _msgSender());
        // }
        // // revoke roles from _grantedRoles
        // delete _grantedRoles[member];
    }
}
