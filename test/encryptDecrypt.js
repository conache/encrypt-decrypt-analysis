const { expect } = require("chai");
const { ethers } = require("hardhat");
const { encryptDecrypt } = require("../main");

const stringToHex = (str) => {
  return "0x" + [...str].map((_, idx) => str.charCodeAt(idx).toString(16)).join("");
};

const hexStringToByteArray = (hexString) => Uint8Array.from(hexString.match(/.{1,2}/g).map((byte) => parseInt(byte, 16)));

const DATA_STR = "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Fusce a est id augue convallis tristique. Suspendisse potenti.";
const KEY = ethers.utils.toUtf8Bytes("This is a test key");

describe("Test custom encryptDecrypt function", () => {
  let dropERC721;

  before(async () => {
    const DropERC721Factory = await ethers.getContractFactory("DropERC721Mock");
    dropERC721 = await DropERC721Factory.deploy();
  });

  it("should have the same output as the contract method output", async () => {
    const contractCallOutput = await dropERC721.encryptDecrypt(ethers.utils.toUtf8Bytes(DATA_STR), KEY);
    const funcCallOutput = await encryptDecrypt(ethers.utils.toUtf8Bytes(DATA_STR), KEY);

    expect(contractCallOutput === funcCallOutput).to.be.true;
  });

  it("decrypted output should match initially encrypted bytes sequence", async () => {
    const encryptedVal = encryptDecrypt(ethers.utils.toUtf8Bytes(DATA_STR), KEY);
    const decryptedVal = encryptDecrypt(hexStringToByteArray(encryptedVal.slice(2)), KEY);

    expect(stringToHex(DATA_STR) === decryptedVal).to.be.true;
  });
});
