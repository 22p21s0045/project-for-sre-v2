import { useState } from 'react'

function TodoForm({ onSubmit }) {
    const [title, setTitle] = useState('')
    const [description, setDescription] = useState('')
    const [isSubmitting, setIsSubmitting] = useState(false)

    const handleSubmit = async (e) => {
        e.preventDefault()

        if (!title.trim()) return

        setIsSubmitting(true)
        try {
            await onSubmit({
                title: title.trim(),
                description: description.trim() || undefined,
            })
            setTitle('')
            setDescription('')
        } finally {
            setIsSubmitting(false)
        }
    }

    return (
        <form className="todo-form" onSubmit={handleSubmit}>
            <div className="input-group">
                <input
                    type="text"
                    className="input"
                    placeholder="What needs to be done?"
                    value={title}
                    onChange={(e) => setTitle(e.target.value)}
                    disabled={isSubmitting}
                    maxLength={255}
                    required
                />
                <input
                    type="text"
                    className="input"
                    placeholder="Description (optional)"
                    value={description}
                    onChange={(e) => setDescription(e.target.value)}
                    disabled={isSubmitting}
                    maxLength={1000}
                />
            </div>
            <button
                type="submit"
                className="btn btn-primary"
                disabled={isSubmitting || !title.trim()}
            >
                {isSubmitting ? '...' : '+ Add'}
            </button>
        </form>
    )
}

export default TodoForm
