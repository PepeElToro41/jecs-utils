import { Entity, Id, InferComponents, Query, Tag, World } from "@rbxts/jecs";

type ConnectionLike =
	| (() => void)
	| {
			Disconnect(): void;
	  }
	| {
			disconnect(): void;
	  }
	| {
			Destroy(): void;
	  }
	| {
			destroy(): void;
	  };

type CallbackFn<T extends Array<unknown>, R = void> = (...args: T) => R;

type EventLike<T extends Array<unknown>> =
	| CallbackFn<T, ConnectionLike | undefined | void>
	| {
			Connect(callback: CallbackFn<T>): ConnectionLike;
	  }
	| {
			connect(callback: CallbackFn<T>): ConnectionLike;
	  }
	| {
			on(callback: CallbackFn<T>): ConnectionLike;
	  };

/** Returns the first entity in the query.
 * @param query: the query to get the first entity from
 * @param predicator: optional filter, if provided, it will return the first entity that matches the predicator
 * @returns entity, T... : the first entity in the query and its component values
 */
export declare function query_first<T extends Id[]>(
	query: Query<T>,
	predicator?: (entity: Entity, ...components: InferComponents<T>) => boolean,
): LuaTuple<[Entity, ...InferComponents<T>]>;

/** Fast way to count the number of entities that match the query.
 * @param query: the query to count entities from
 * @returns count: the number of entities
 */
export function query_count(query: Query<Id[]>): number;

/** Fast way to gather all entities that match the query into an array.
 * @param query: the query to get entities from
 * @returns entities: an array of entities
 */
export function query_entities(query: Query<Id[]>): Entity[];

/** Creates an iterator with all the entities that the query components have changed and match the query.
 * @param query: the query to get entities from
 * @returns iterator: an iterator with all the entities, can also manually iterate with .iter()
 */
export function query_changed(query: Query<Id[]>): {
	iter: () => IterableFunction<Entity>;
	empty: () => boolean;
	disconnect: () => void;
} & IterableFunction<Entity>;

export function query_random<T extends Id[]>(query: Query<T>): LuaTuple<[Entity, ...InferComponents<T>]>;

export function collect<T extends Array<unknown>>(
	event: EventLike<T>,
): LuaTuple<[IterableFunction<LuaTuple<[number, ...T]>>, () => void]>;

export function interval(time: number): () => boolean;

interface Ref {
	(key: defined, initer?: (entity: Entity) => void): Entity;
	get: (key: defined, initer?: (entity: Entity) => void) => Entity;
	set: (key: defined, entity: Entity) => void;
	find: (key: defined) => Entity | undefined;
	delete: (key: defined) => void;
}

export const ref: Ref;

export interface Observer {
	disconnect: () => void;
}

export interface Monitor {
	disconnect: () => void;
	added: (callback: (entity: Entity) => void) => void;
	removed: (callback: (entity: Entity) => void) => void;
}

export function observer(query: Query<Id[]>, callback: (entity: Entity) => void): Observer;
export function monitor(query: Query<Id[]>): Monitor;

interface JecsUtils {
	world: (world: World) => void;

	__world: World;
}
export function world(world: World): void;

export const is_a: Tag;
export const IsA: Tag;

declare const jecs_utils: JecsUtils;
export default jecs_utils;
