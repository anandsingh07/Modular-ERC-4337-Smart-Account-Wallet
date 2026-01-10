"use client";

export default function UserInfo({ address }) {
  if (!address) return null;

  return (
    <div style={{ marginTop: "20px" }}>
      <h3>Logged In Address</h3>
      <p>{address}</p>
    </div>
  );
}
