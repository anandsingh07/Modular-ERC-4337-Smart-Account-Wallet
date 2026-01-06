import {Web3Auth} from "@web3auth/modal";
import { CHAIN_NAMESPACES } from "@web3auth/base";
import { chainConfig } from "viem/zksync";

export const Web3Auth = new Web3Auth({
    clientId: process.env.NEXT_PUBLIC_WEB3AUTH_CLIENT_ID,
    chainConfig :{
        chainNameSpace : CHAIN_NAMESPACES.EIP155 ,
        chainId : "0x14a54" ,
        rpcTarget:
                "https://base-sepolia.g.alchemy.com/v2/" +
                  process.env.NEXT_PUBLIC_ALCHEMY_API_KEY,

    }
}) 