import { Entity, Id, InferComponents, Query, World } from "@rbxts/jecs";
import { Derivable, Source } from "@rbxts/vide";

export function use_entity_get<T>(entity: Derivable<Entity | undefined>, id: Entity<T>): Source<T | undefined>;

export function use_entity_has<T>(entity: Derivable<Entity | undefined>, id: Entity<T>): Source<boolean>;

export function use_query_first<T extends Id[]>(
	query: Derivable<Query<T>>,
	predicator?: (entity: Entity, ...components: InferComponents<T>) => boolean,
): Source<Entity | undefined>;

export function use_query(query: Derivable<Query<Id[]>>): Source<Entity[]>;

export function use_target<T extends Id = Entity>(entity: Derivable<Entity | undefined>, relation: Id): Source<T>;

////////////////////////////////////////////////////////////////////////////////

export function useEntityGet<T>(entity: Derivable<Entity | undefined>, id: Entity<T>): Source<T | undefined>;

export function useEntityHas<T>(entity: Derivable<Entity | undefined>, id: Entity<T>): Source<boolean>;

export function useQueryFirst<T extends Id[]>(
	query: Derivable<Query<T>>,
	predicator?: (entity: Entity, ...components: InferComponents<T>) => boolean,
): Source<Entity | undefined>;

export function useQuery(query: Derivable<Query<Id[]>>): Source<Entity[]>;

export function useTarget<T extends Id = Entity>(entity: Derivable<Entity | undefined>, relation: Id): Source<T>;

interface JecsVide {
	world: (world: World) => void;
}

export function world(world: World): void;

declare const jecs_vide: JecsVide;
export default jecs_vide;
