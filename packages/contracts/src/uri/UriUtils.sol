// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

library UriUtils {
  string constant START = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350">'
  '<style>.base { font-family: serif; font-size: 32px; }</style>'
  '<rect width="100%" height="100%" fill="#1e1e1e" stroke="#3c3c3c" stroke-width="1" />';
  string constant END = '</svg>';

  string constant ATTRS_HEADER_TYPE = ' x="50%" class="base" text-anchor="middle" fill="#4ec9b0" ';
  string constant ATTRS_BASE = ' class="base" ';
  string constant ATTRS_NUM = ' class="base" fill="#b5cea8" ';
  string constant ATTRS_STRING = ' class="base" fill="#ce9178" ';
  string constant ATTRS_KEY = ' class="base" fill="#9cdcfe" ';
}
