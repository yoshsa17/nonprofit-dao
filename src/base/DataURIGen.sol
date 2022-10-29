// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/**
 * @title DataURI Generation contract
 *
 * @dev This contract helps to generate DataURIs(SVG data) for SBRTs.
 * NOTE: This design borrows heavily from the Uniswap V3 Non-Fungible Position token.
 */
contract DataURIGen {
    using Strings for address;
    using Strings for uint256;

    /**
     * @dev Generates a DataURI.
     */
    function getDataURI(
        uint256 tokenId,
        address owner,
        string[] memory roles,
        string memory status,
        uint256 timestamp,
        address acceptedBy,
        uint256 reputationCount,
        uint256 evaluateCount,
        uint256 votingCount,
        uint256 proposalCount
    ) public pure returns (string memory) {
        // use hsv values to generate a color
        // uint256 val = uint256(keccak256(abi.encodePacked(acceptedBy, tokenId, owner)));

        string memory background = genBackgroundSVG(reputationCount);
        string memory text = genTextSVG(
            tokenId,
            owner,
            roles,
            status,
            timestamp,
            acceptedBy,
            reputationCount,
            evaluateCount,
            votingCount,
            proposalCount
        );

        // TODO:: add metadatas
        return
            string(
                abi.encodePacked(
                    "data:image/svg+xml;base64,",
                    Base64.encode(
                        bytes(
                            string(
                                abi.encodePacked(
                                    '<svg class="svgBody" width="300" height="185" viewBox="0 0 300 185" xmlns="http://www.w3.org/2000/svg">',
                                    background,
                                    text,
                                    "</svg>"
                                )
                            )
                        )
                    )
                )
            );
    }

    /**
     * @dev Generates background svg
     */
    function genBackgroundSVG(uint256 reputationCount) public pure returns (string memory) {
        // uint256 h = val % 361;
        // uint256 s = (val % 61) + 40;
        string memory color;
        if (reputationCount < 5) {
            color = "#00c000";
        } else if (reputationCount < 10) {
            color = "#0022FF";
        } else if (reputationCount < 15) {
            color = "#F7FF00";
        } else if (reputationCount < 20) {
            color = "#00F7FF";
        } else {
            color = "#FFFFFF";
        }

        return
            string(
                abi.encodePacked(
                    "<defs>"
                    ' <linearGradient id="gradient" x1="0%" y1="0%" x2="0" y2="100%">',
                    ' <stop offset="0%" style="stop-color:',
                    color,
                    ';stop-opacity:1" />',
                    ' <stop offset="100%" style="stop-color:black;" />',
                    " </linearGradient>",
                    " </defs>",
                    ' <rect width="300" height="185" rx="10" fill="url(#gradient)" />',
                    ' <rect x="5" y="5" width="290" height="175" rx="10" fill="transparent" stroke="white" opacity="0.8" />',
                    ' <rect x="14" y="170" rx="3" width="42" height="13" fill="black"  />'
                )
            );
    }

    /**
     * @dev Generates text svg
     */
    function genTextSVG(
        uint256 tokenId,
        address owner,
        string[] memory roles,
        string memory status,
        uint256 timestamp,
        address acceptedBy,
        uint256 reputationCount,
        uint256 evaluateCount,
        uint256 votingCount,
        uint256 proposalCount
    ) public pure returns (string memory) {
        string memory textTop = genTextTopSVG(owner, acceptedBy, roles, status);
        string memory textMid = genTextMidSVG(reputationCount, evaluateCount, votingCount, proposalCount);
        string memory textBottom = genTextBottomSVG(tokenId, timestamp);
        return string(abi.encodePacked(textTop, textMid, textBottom));
    }

    /**
     * @dev Generates text svg (top)
     */
    function genTextTopSVG(
        address owner,
        address acceptedBy,
        string[] memory roles,
        string memory status
    ) public pure returns (string memory) {
        string memory catRoles = concatStrings(roles);

        return
            string(
                abi.encodePacked(
                    ' <text x="20" y="30" class="tiny" fill="white" >Nonprofit DAO</text>',
                    '<text x="20" y="40" class="small" fill="white" >',
                    owner.toHexString(),
                    "</text>",
                    '<text x="20" y="50" class="tiny" fill="white" >Accepted by: ',
                    acceptedBy.toHexString(),
                    "</text>",
                    ' <text x="20" y="60" class="tiny" fill="white" >Roles: ',
                    catRoles,
                    "</text>",
                    ' <text x="20" y="70" class="tiny" fill="white" >Status: ',
                    status,
                    "</text>"
                )
            );
    }

    /**
     * @dev Generates text svg (middle)
     */
    function genTextMidSVG(
        uint256 reputationCount,
        uint256 evaluationCount,
        uint256 votingCount,
        uint256 proposalCount
    ) public pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    ' <text x="20" y="90" class="tiny" fill="white" >Reputations: ',
                    reputationCount.toString(),
                    "</text>",
                    '<text x="20" y="100" class="tiny" fill="white" >Evaluations: ',
                    evaluationCount.toString(),
                    "</text>",
                    '<text x="20" y="110" class="tiny" fill="white" >Votings: ',
                    votingCount.toString(),
                    "</text>",
                    '<text x="20" y="120" class="tiny" fill="white" >Proposal Submissions: ',
                    proposalCount.toString(),
                    "</text>"
                )
            );
    }

    /**
     * @dev Generates text svg (bottom)
     */
    function genTextBottomSVG(uint256 tokenId, uint256 timestamp) public pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '<text x="17" y="182" class="small" fill="white" ># ',
                    tokenId.toString(),
                    "</text>",
                    '<text x="180" y="170" class="tiny" fill="white" >Updated tiemstamp: ',
                    timestamp.toString(),
                    "</text>",
                    '<style>.svgBody {font-family: "Courier New" } .tiny {font-size:6px; } .small {font-size: 10px;}</style>'
                )
            );
    }

    function concatStrings(string[] memory words) internal pure returns (string memory) {
        string memory result = "";
        for (uint256 i = 0; i < words.length; i++) {
            result = string(abi.encodePacked(result, words[i], " "));
        }
        return result;
    }
}
