"use client";

export default function RootLayout({ children }) {
  return (
    <html lang="en">
      <body style={{ padding: "40px", fontFamily: "sans-serif" }}>
        {children}
      </body>
    </html>
  );
}
