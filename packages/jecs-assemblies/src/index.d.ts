import { Entity, Tag, World } from "@rbxts/jecs";

interface JecsAssemblies {
	transform: Entity<CFrame>;
	relative: Entity<CFrame>;
	pivot: Tag;

	world: () => void;
	system: () => void;

	__alive_tracking__: Tag;
}

export const transform: Entity<CFrame>;
export const relative: Entity<CFrame>;
export const pivot: Tag;

export function world(world: World): void;
export function system(): void;
export function swap_pivot(entity: Entity, pivot: Entity, relative?: CFrame): void;

declare const jecs_assemblies: JecsAssemblies;
export default jecs_assemblies;
