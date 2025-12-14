const API_BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:3000'

async function handleResponse(response) {
  if (!response.ok) {
    const error = await response.json().catch(() => ({}))
    throw new Error(error.message || `HTTP error! status: ${response.status}`)
  }
  
  // Handle 204 No Content
  if (response.status === 204) {
    return null
  }
  
  return response.json()
}

export async function getTodos() {
  const response = await fetch(`${API_BASE_URL}/todos`)
  return handleResponse(response)
}

export async function getTodo(id) {
  const response = await fetch(`${API_BASE_URL}/todos/${id}`)
  return handleResponse(response)
}

export async function createTodo(todoData) {
  const response = await fetch(`${API_BASE_URL}/todos`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(todoData),
  })
  return handleResponse(response)
}

export async function updateTodo(id, todoData) {
  const response = await fetch(`${API_BASE_URL}/todos/${id}`, {
    method: 'PATCH',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(todoData),
  })
  return handleResponse(response)
}

export async function toggleTodo(id) {
  const response = await fetch(`${API_BASE_URL}/todos/${id}/toggle`, {
    method: 'PATCH',
  })
  return handleResponse(response)
}

export async function deleteTodo(id) {
  const response = await fetch(`${API_BASE_URL}/todos/${id}`, {
    method: 'DELETE',
  })
  return handleResponse(response)
}
