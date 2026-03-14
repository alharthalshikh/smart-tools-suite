import { createBrowserRouter, RouterProvider } from "react-router-dom";
import { AppLayout } from "./components/AppLayout";
import {
  HomePage,
  PdfPage,
  QrBarcodePage,
  ImageConverterPage,
  OptimizerPage,
  VideoConverterPage,
  AudioToolsPage,
  ColorPickerPage,
  AboutPage,
  BgRemoverPage,
  SpeedTestPage,
  DeviceInfoPage,
  DocScannerPage
} from "./pages";

const router = createBrowserRouter([
  {
    path: "/",
    element: <AppLayout />,
    children: [
      { index: true, element: <HomePage /> },
      { path: "pdf", element: <PdfPage /> },
      { path: "qr", element: <QrBarcodePage /> },
      { path: "images", element: <ImageConverterPage /> },
      { path: "optimize", element: <OptimizerPage /> },
      { path: "video-to-audio", element: <VideoConverterPage /> },
      { path: "audio-tools", element: <AudioToolsPage /> },
      { path: "color-picker", element: <ColorPickerPage /> },
      { path: "bg-remover", element: <BgRemoverPage /> },
      { path: "speedtest", element: <SpeedTestPage /> },
      { path: "device-info", element: <DeviceInfoPage /> },
      { path: "scanner", element: <DocScannerPage /> },
      { path: "about", element: <AboutPage /> },
    ],
  },
]);

export function AppRouter() {
  return <RouterProvider router={router} />;
}
