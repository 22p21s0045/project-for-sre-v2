function TodoList({ todos, onToggle, onDelete }) {
    if (todos.length === 0) {
        return (
            <div className="empty-state">
                <div className="empty-state-icon">📝</div>
                <p>No todos yet. Add one to get started!</p>
            </div>
        )
    }

    return (
        <div className="todo-list">
            {todos.map((todo) => (
                <div
                    key={todo.id}
                    className={`todo-item ${todo.completed ? 'completed' : ''}`}
                >
                    <div
                        className={`checkbox ${todo.completed ? 'checked' : ''}`}
                        onClick={() => onToggle(todo.id)}
                        role="checkbox"
                        aria-checked={todo.completed}
                        tabIndex={0}
                        onKeyDown={(e) => e.key === 'Enter' && onToggle(todo.id)}
                    />

                    <div className="todo-content">
                        <div className="todo-title">{todo.title}</div>
                        {todo.description && (
                            <div className="todo-description">{todo.description}</div>
                        )}
                    </div>

                    <div className="todo-actions">
                        <button
                            className="btn btn-icon btn-danger"
                            onClick={() => onDelete(todo.id)}
                            aria-label="Delete todo"
                        >
                            🗑️
                        </button>
                    </div>
                </div>
            ))}
        </div>
    )
}

export default TodoList
