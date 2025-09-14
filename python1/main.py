
from tasks.task_manager import TaskManager

def main():
    task_manager = TaskManager()

    while True:
        print("\nTask Manager")
        print("1. Add task")
        print("2. View tasks")
        print("3. Remove task")
        print("4. Exit")

        choice = input("Enter your choice: ")

        if choice == '1':
            task = input("Enter the task description: ")
            task_manager.add_task(task)
        elif choice == '2':
            task_manager.view_tasks()
        elif choice == '3':
            task_id = int(input("Enter the task ID to remove: "))
            task_manager.remove_task(task_id)
        elif choice == '4':
            print("Exiting Task Manager...")
            break
        else:
            print("Invalid choice, please try again.")

if __name__ == "__main__":
    main()
