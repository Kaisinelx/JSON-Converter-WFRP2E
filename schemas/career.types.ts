// Skill or Talent atom
export interface NamedEntity {
  name: string;
  spec?: string;  // optional specialisation, e.g. "Classical"
}

// Group that requires picking N options
export interface PickGroup {
  pick: number;
  options?: NamedEntity[];      // for OR choices
  anyCategory?: string;         // for "Academic Knowledge (any two)"
}

// Skill/Talent Advances
export interface Advances {
  required: NamedEntity[];
  groups: PickGroup[];
}

// Characteristic caps
export interface AdvanceScheme {
  WS: number;
  BS: number;
  S: number;
  T: number;
  Ag: number;
  Int: number;
  WP: number;
  Fel: number;
  A: number;
  W: number;
  SB: number;
  TB: number;
  M: number;
  Mag: number;
  IP: number;
  FP: number;
}

// Final Career object
export interface Career {
  id: string;               // slugified id
  name: string;
  type: "basic" | "advanced";
  description: string;
  advanceScheme: AdvanceScheme;
  skillAdvances: Advances;
  talentAdvances: Advances;
  trappings: string[];
  careerEntries: string[];
  careerExits: string[];
}
