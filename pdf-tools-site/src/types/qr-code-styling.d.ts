declare module "qr-code-styling" {
  export type QRCodeStylingOptions = any;

  export default class QRCodeStyling {
    constructor(options?: QRCodeStylingOptions);
    append(container: HTMLElement): void;
    update(options?: QRCodeStylingOptions): void;
    download(options?: { name?: string; extension?: "png" | "jpeg" | "webp" | "svg" }): void;
    getRawData(extension?: "png" | "jpeg" | "webp" | "svg"): Promise<Blob>;
  }
}
