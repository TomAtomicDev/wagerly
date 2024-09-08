import { Lato } from "next/font/google";
import Header from "./components/Header";
import "@rainbow-me/rainbowkit/styles.css";
import { ThemeProvider } from "~~/components/ThemeProvider";
import "~~/styles/globals.css";
import { getMetadata } from "~~/utils/scaffold-eth/getMetadata";

const lato = Lato({
  variable: "--font-lato",
  subsets: ["latin"],
  weight: ["100", "300", "400", "700", "900"],
});

export const metadata = getMetadata({
  title: "Wagerly",
  description: "Plataforma de apuestas descentralizadas en Kinto",
});

/* const ScaffoldEthApp = ({ children }: { children: React.ReactNode }) => {
  return (
    <html suppressHydrationWarning>
      <body>
        <ThemeProvider enableSystem>
          <ScaffoldEthAppWithProviders>{children}</ScaffoldEthAppWithProviders>
        </ThemeProvider>
      </body>
    </html>
  );
}; */

const ScaffoldEthApp = ({ children }: { children: React.ReactNode }) => {
  return (
    <html className={lato.variable} suppressHydrationWarning>
      <body>
        <ThemeProvider defaultTheme="light" enableSystem={false} forcedTheme="light">
          <Header />
          {children}
        </ThemeProvider>
      </body>
    </html>
  );
};

export default ScaffoldEthApp;
