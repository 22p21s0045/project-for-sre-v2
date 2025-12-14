import { useState, useEffect } from 'react'
import TodoList from './components/TodoList'
import TodoForm from './components/TodoForm'
import { getTodos, createTodo, toggleTodo, deleteTodo } from './services/api'

function App() {
    const [todos, setTodos] = useState([])
    const [loading, setLoading] = useState(true)
    const [error, setError] = useState(null)

    useEffect(() => {
        fetchTodos()
    }, [])

    const fetchTodos = async () => {
        try {
            setLoading(true)
            setError(null)
            const data = await getTodos()
            setTodos(data)
        } catch (err) {
            setError('Failed to fetch todos. Please try again.')
            console.error('Error fetching todos:', err)
        } finally {
            setLoading(false)
        }
    }

    const handleAddTodo = async (todoData) => {
        try {
            setError(null)
            const newTodo = await createTodo(todoData)
            setTodos([newTodo, ...todos])
        } catch (err) {
            setError('Failed to add todo. Please try again.')
            console.error('Error adding todo:', err)
        }
    }

    const handleToggleTodo = async (id) => {
        try {
            setError(null)
            const updatedTodo = await toggleTodo(id)
            setTodos(todos.map(todo =>
                todo.id === id ? updatedTodo : todo
            ))
        } catch (err) {
            setError('Failed to update todo. Please try again.')
            console.error('Error toggling todo:', err)
        }
    }

    const handleDeleteTodo = async (id) => {
        try {
            setError(null)
            await deleteTodo(id)
            setTodos(todos.filter(todo => todo.id !== id))
        } catch (err) {
            setError('Failed to delete todo. Please try again.')
            console.error('Error deleting todo:', err)
        }
    }

    const completedCount = todos.filter(todo => todo.completed).length
    const pendingCount = todos.length - completedCount

    return (
        <div className="container">
            <header className="header">
                <h1>✨ Todo List</h1>
                <p>Stay organized, track your progress</p>
            </header>

            <main className="card">
                {error && <div className="error">{error}</div>}

                <TodoForm onSubmit={handleAddTodo} />

                {loading ? (
                    <div className="loading">
                        <div className="spinner"></div>
                    </div>
                ) : (
                    <TodoList
                        todos={todos}
                        onToggle={handleToggleTodo}
                        onDelete={handleDeleteTodo}
                    />
                )}

                {!loading && todos.length > 0 && (
                    <div className="stats">
                        <div className="stat">
                            <div className="stat-value">{todos.length}</div>
                            <div className="stat-label">Total</div>
                        </div>
                        <div className="stat">
                            <div className="stat-value">{completedCount}</div>
                            <div className="stat-label">Completed</div>
                        </div>
                        <div className="stat">
                            <div className="stat-value">{pendingCount}</div>
                            <div className="stat-label">Pending</div>
                        </div>
                    </div>
                )}
            </main>
        </div>
    )
}

export default App
