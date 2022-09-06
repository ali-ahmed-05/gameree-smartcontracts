// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

import './IBEP165.sol';

/**
 * BEP1155 interface with mint, burn, and attached data support for fungible & non-fungible tokens.
 * Non-fungible tokens also have support for custom URI's.
 */
 interface IBEP1155Mixed is IBEP165 {
  function create(
    bool is_fungible  
    ) external returns (uint256);

  function mintNonFungible(
    uint256 type_id,
    address[] memory to,
    bytes memory data
  ) external;

  function mintNonFungibleWithURI(
    uint256 type_id,
    address[] memory to,
    bytes memory data,
    string memory _uri
  ) external;

  function mintFungible(
    uint256 type_id,
    address[] memory to,
    uint256[] memory amounts,
    bytes memory data
  ) external;


  function setApprovalForAllWithData(
    address operator,
    bool approved
  ) external;

  function uri(
    uint256 id
  ) external returns (string memory);

  function baseTokenUri() external returns(string memory);
 }