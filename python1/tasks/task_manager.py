
from tasks.task import Task

class TaskManager:
    def __init__(self):
        self.tasks = []
        self.next_task_id = 1

    def add_task(self, description):
        task = Task(description, self.next_task_id)
        self.tasks.append(task)
        self.next_task_id += 1
        print(f"Task added: {task}")

    def view_tasks(self):
        if not self.tasks:
            print("No tasks available.")
        else:
            for task in self.tasks:
                print(task)

    def remove_task(self, task_id):
        task_to_remove = None
        for task in self.tasks:
            if task.task_id == task_id:
                task_to_remove = task
                break
        if task_to_remove:
            self.tasks.remove(task_to_remove)
            print(f"Task removed: {task_to_remove}")
        else:
            print(f"Task with ID {task_id} not found.")
