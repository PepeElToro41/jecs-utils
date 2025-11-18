import { Entity, World } from "@rbxts/jecs";

export interface OptionalStyle {
	alwaysOnTop?: boolean;
	color?: Color3;
	layer?: number;
	advanced?: boolean;
	transparency?: number;
	scale?: number;
}

type GizmoComponent = Entity<OptionalStyle>;

interface Gizmo {
	cframe: GizmoComponent;
	position: GizmoComponent;
	direction: GizmoComponent;
	distance: GizmoComponent;
	lookvector: GizmoComponent;
}

interface JecsGizmo {
	cframe: Entity<CFrame>;
	position: Entity<Vector3>;
	direction: Entity<Vector3>;

	enabled: boolean;
	gizmo: Gizmo;

	world: (world: World) => void;
	system: () => void;
}

export const gizmo: Gizmo;

export function world(world: World): void;
export function system(): void;

declare const jecs_gizmo: JecsGizmo;
export default jecs_gizmo;
