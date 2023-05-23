import { ethers } from "hardhat"

export const getLastTimestamp = async () => {
    const blockNumBefore = await ethers.provider.getBlockNumber();
    const blockBefore = await ethers.provider.getBlock(blockNumBefore);
    return blockBefore.timestamp;
}

export const day = 60 * 60 * 24;