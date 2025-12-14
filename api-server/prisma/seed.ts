import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function main() {
  console.log('Seeding database...');

  await prisma.todo.deleteMany();

  const todos = await prisma.todo.createMany({
    data: [
      {
        title: 'Learn NestJS',
        description: 'Study NestJS framework and its features',
        completed: false,
      },
      {
        title: 'Set up Prometheus',
        description: 'Configure Prometheus for metrics collection',
        completed: false,
      },
      {
        title: 'Implement Golden Signals',
        description: 'Add Error, Traffic, Saturation, and Latency metrics',
        completed: false,
      },
      {
        title: 'Create Grafana Dashboard',
        description: 'Build dashboard to visualize SRE metrics',
        completed: false,
      },
      {
        title: 'Write Documentation',
        description: 'Document the monitoring setup',
        completed: true,
      },
    ],
  });

  console.log(`Created ${todos.count} todos`);
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
