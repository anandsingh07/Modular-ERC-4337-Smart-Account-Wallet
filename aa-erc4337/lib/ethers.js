"use client";

import { ethers } from "ethers";

export const getEthersSigner = async (provider) => {
  if (!provider) return null;

  const ethersProvider = new ethers.BrowserProvider(provider);
  const signer = await ethersProvider.getSigner();

  return signer;
};
