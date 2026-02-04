// Core domain types for the Fantasy Baseball Draft Kit

export interface League {
  id: number
  name: string
  teamCount: number
  auctionBudget: number
  keeperLimit: number
  rosterConfig: RosterConfig
  createdAt: string
  updatedAt: string
}

export interface RosterConfig {
  C: number
  '1B': number
  '2B': number
  SS: number
  '3B': number
  CI: number
  MI: number
  OF: number
  UTIL: number
  SP: number
  RP: number
  P: number
  BN: number
}

export interface Team {
  id: number
  leagueId: number
  name: string
  budgetRemaining: number
  roster: DraftPick[]
  createdAt: string
  updatedAt: string
}

export interface Player {
  id: number
  name: string
  positions: Position[]
  mlbTeam: string
  projections: PlayerProjections
  calculatedValue: number | null
  isDrafted: boolean
  createdAt: string
  updatedAt: string
}

export type Position = 'C' | '1B' | '2B' | 'SS' | '3B' | 'OF' | 'SP' | 'RP' | 'P'

export interface PlayerProjections {
  // Batting stats
  pa?: number
  ab?: number
  r?: number
  hr?: number
  rbi?: number
  sb?: number
  avg?: number
  obp?: number
  slg?: number

  // Pitching stats
  ip?: number
  w?: number
  k?: number
  era?: number
  whip?: number
  sv?: number
  hld?: number

  // Z-scores for value calculation
  zScores?: {
    [category: string]: number
  }
}

export interface DraftPick {
  id: number
  leagueId: number
  teamId: number
  playerId: number
  price: number
  isKeeper: boolean
  pickNumber: number
  player?: Player
  team?: Team
  createdAt: string
  updatedAt: string
}

export interface KeeperHistory {
  id: number
  playerId: number
  teamId: number
  year: number
  price: number
  player?: Player
  team?: Team
  createdAt: string
  updatedAt: string
}

export interface AuctionValueBreakdown {
  category: string
  dollarPerUnit: number
  playerValue: number
}

export interface TeamCategoryStrength {
  category: string
  projectedTotal: number
  leagueAverage: number
  strength: 'strong' | 'weak' | 'average'
}

// API Response types
export interface ApiResponse<T> {
  data: T
  message?: string
}

export interface ApiError {
  error: string
  details?: Record<string, string[]>
}

// Filter and sort types
export interface PlayerFilters {
  searchTerm?: string
  positions?: Position[]
  mlbTeams?: string[]
  isDrafted?: boolean
  minValue?: number
  maxValue?: number
}

export type SortField =
  | 'name'
  | 'calculatedValue'
  | 'positions'
  | 'mlbTeam'
  | keyof PlayerProjections

export type SortDirection = 'asc' | 'desc'

export interface SortConfig {
  field: SortField
  direction: SortDirection
}
