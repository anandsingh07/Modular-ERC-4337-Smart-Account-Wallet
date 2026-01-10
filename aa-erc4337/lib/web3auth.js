"use client";

import { Web3Auth } from "@web3auth/modal";
import { CHAIN_NAMESPACES } from "@web3auth/base";

let web3authInstance = null;

export const initWeb3Auth = async () => {
  if (web3authInstance) return web3authInstance;

  const web3auth = new Web3Auth({
    clientId: process.env.NEXT_PUBLIC_WEB3AUTH_CLIENT_ID,

    
    web3AuthNetwork: "sapphire_devnet",

    chainConfig: {
      chainNamespace: CHAIN_NAMESPACES.EIP155,

      
      chainId: "0xaa36a7", 
      rpcTarget: "https://rpc.sepolia.org",
    },
  });

  
  await web3auth.init();

  web3authInstance = web3auth;
  return web3authInstance;
};

export const connectWeb3Auth = async () => {
  const web3auth = await initWeb3Auth();
  return await web3auth.connect();
};

export const logoutWeb3Auth = async () => {
  if (!web3authInstance) return;
  await web3authInstance.logout();
  web3authInstance = null;
};
