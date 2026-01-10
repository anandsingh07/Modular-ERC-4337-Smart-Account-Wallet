"use client";

import { useState } from "react";
import LoginButton from "@/components/LoginButton";
import UserInfo from "@/components/UserInfo";
import { getEthersSigner } from "@/lib/ethers";

export default function Home() {
  const [provider, setProvider] = useState(null);
  const [address, setAddress] = useState(null);

  const handleLogin = async (provider) => {
    setProvider(provider);

    const signer = await getEthersSigner(provider);
    const address = await signer.getAddress();

    setAddress(address);
  };

  const handleLogout = () => {
    setProvider(null);
    setAddress(null);
  };

  return (
    <main>
      <h1>Phase 1 — Web3Auth Login</h1>

      <LoginButton
        onLogin={handleLogin}
        onLogout={handleLogout}
        isLoggedIn={!!address}
      />

      <UserInfo address={address} />
    </main>
  );
}
