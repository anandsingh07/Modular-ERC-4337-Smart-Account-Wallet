"use client";

import { connectWeb3Auth, logoutWeb3Auth } from "@/lib/web3auth";

export default function LoginButton({ onLogin, onLogout, isLoggedIn }) {
  const handleLogin = async () => {
    const provider = await connectWeb3Auth();
    onLogin(provider);
  };

  const handleLogout = async () => {
    await logoutWeb3Auth();
    onLogout();
  };

  return (
    <button
      onClick={isLoggedIn ? handleLogout : handleLogin}
      style={{
        padding: "10px 20px",
        background: "#6366f1",
        color: "white",
        borderRadius: "8px",
      }}
    >
      {isLoggedIn ? "Logout" : "Login with Web3Auth"}
    </button>
  );
}
