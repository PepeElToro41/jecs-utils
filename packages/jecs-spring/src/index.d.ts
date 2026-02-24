import { Entity, Tag, World } from "@rbxts/jecs";
import { Spring, SpringOptions } from "@rbxts/ripple";

interface JecsSpring {
	options: Entity<SpringOptions>;
	goal: Tag;
	completed: Tag;
	motion: Entity<Spring>;

	world: (world: World) => void;
	system: (delta: number) => void;
}

declare const jecs_spring: JecsSpring;

export const options: Entity<SpringOptions>;
export const goal: Tag;
export const completed: Tag;
export const motion: Entity<Spring>;

export function world(world: World): void;
export function system(delta: number): void;

export default jecs_spring;
