declare module '@asymmetric-effort/specifyjs' {
  export type Key = string | number | null;
  export type Ref<T = unknown> = ((instance: T | null) => void) | { current: T | null } | null;
  export type Props = Record<string, unknown> & { children?: SpecNode; key?: Key; ref?: Ref };
  export type SpecChild = SpecElement | string | number | boolean | null | undefined;
  export type SpecNode = SpecChild | SpecNode[];
  export type FunctionComponent<P extends Props = Props> = (props: P) => SpecNode;
  export type ComponentType<P extends Props = Props> = FunctionComponent<P> | string | symbol;

  export interface SpecElement<P extends Props = Props> {
    $$typeof: symbol;
    type: ComponentType<P>;
    props: P;
    key: Key;
    ref: Ref;
  }

  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  export function createElement(
    type: string | ((props: any) => any),
    config: Record<string, unknown> | null,
    ...children: SpecNode[]
  ): SpecElement;

  export const Fragment: symbol;

  export function useState<T>(initialState: T | (() => T)): [T, (action: T | ((prev: T) => T)) => void];
  export function useEffect(create: () => void | (() => void), deps?: readonly unknown[]): void;
  export function useCallback<T extends (...args: unknown[]) => unknown>(callback: T, deps: readonly unknown[]): T;
  export function useMemo<T>(factory: () => T, deps: readonly unknown[]): T;
  export function useRef<T>(initialValue?: T): { current: T };
  export function useContext<T>(context: unknown): T;
  export function useReducer<S, A>(reducer: (state: S, action: A) => S, initialArg: S, init?: (arg: S) => S): [S, (action: A) => void];
}

declare module '@asymmetric-effort/specifyjs/dom' {
  import type { SpecNode } from '@asymmetric-effort/specifyjs';

  export interface Root {
    render(children: SpecNode): void;
    unmount(): void;
  }

  export function createRoot(container: Element | DocumentFragment): Root;
  export function render(element: SpecNode, container: Element, callback?: () => void): void;
}

declare module '@asymmetric-effort/specifyjs/components' {
  import type { SpecElement, Props } from '@asymmetric-effort/specifyjs';

  export interface FooterProps {
    left?: unknown;
    center?: unknown;
    right?: unknown;
    borderTop?: string;
    background?: string;
    color?: string;
    fontSize?: string;
    padding?: string;
    maxWidth?: string;
    className?: string;
    ariaLabel?: string;
  }

  export function Footer(props: FooterProps): SpecElement<Props>;
}

declare module '@asymmetric-effort/specifyjs/server' {
  import type { SpecNode } from '@asymmetric-effort/specifyjs';

  export function renderToString(element: SpecNode): string;
  export function renderToStaticMarkup(element: SpecNode): string;
}

declare module '@asymmetric-effort/specifyjs/build' {
  import type { Plugin } from 'vite';

  export interface SeoPluginConfig {
    siteUrl: string;
    title?: string;
    description?: string;
    routes?: string[];
    docsDir?: string;
    npmPackage?: string;
    author?: string;
    license?: string;
    robotsRules?: string[];
    repository?: string;
  }

  export interface NoscriptSection {
    id: string;
    title: string;
    html: string;
  }

  export interface NoscriptPluginConfig {
    title?: string;
    description?: string;
    sections: NoscriptSection[];
    copyright?: string;
    classPrefix?: string;
    maxContentSize?: number;
  }

  export function specifyJsSeoPlugin(config: SeoPluginConfig): Plugin;
  export function specifyJsNoscriptPlugin(config: NoscriptPluginConfig): Plugin;
}

declare const __APP_VERSION__: string;

declare module '@asymmetric-effort/specifyjs/jsx-runtime' {
  export function jsx(type: unknown, props: Record<string, unknown>, key?: string | number): unknown;
  export function jsxs(type: unknown, props: Record<string, unknown>, key?: string | number): unknown;
  export const Fragment: symbol;
}
