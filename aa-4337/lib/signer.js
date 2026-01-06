import { LocalAccountSigner } from "@alchemy/aa-accounts";
import { createWalletClient , custom } from "viem";

export async function getAlchemySigner(provider) {
    const walletClient = createWalletClient({
        transport : custom(provider),
    });
    const [address] = await walletClient.getAddresses();
    return LocalAccountSigner.custom(walletClient , address);
    
}