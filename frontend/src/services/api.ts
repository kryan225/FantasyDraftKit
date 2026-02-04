import axios, { AxiosInstance, AxiosError } from 'axios'
import type { ApiError } from '../types'

/**
 * Base API client configuration
 * Centralizes all HTTP communication with the backend Rails API
 */
class ApiClient {
  private client: AxiosInstance

  constructor() {
    this.client = axios.create({
      baseURL: import.meta.env.VITE_API_URL || 'http://localhost:3639',
      headers: {
        'Content-Type': 'application/json',
      },
      timeout: 10000,
    })

    // Response interceptor for consistent error handling
    this.client.interceptors.response.use(
      (response) => response,
      (error: AxiosError<ApiError>) => {
        return Promise.reject(this.handleError(error))
      }
    )
  }

  /**
   * Transform API errors into a consistent format
   */
  private handleError(error: AxiosError<ApiError>): Error {
    if (error.response?.data) {
      const apiError = error.response.data
      return new Error(apiError.error || 'An unexpected error occurred')
    }

    if (error.message === 'Network Error') {
      return new Error('Unable to connect to server. Please check your connection.')
    }

    return new Error(error.message || 'An unexpected error occurred')
  }

  public getClient(): AxiosInstance {
    return this.client
  }
}

// Singleton instance
export const apiClient = new ApiClient().getClient()
