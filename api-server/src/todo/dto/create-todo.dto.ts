import { IsString, IsOptional, IsBoolean, MaxLength } from 'class-validator';

export class CreateTodoDto {
  @IsString()
  @MaxLength(255)
  title: string;

  @IsString()
  @IsOptional()
  @MaxLength(1000)
  description?: string;

  @IsBoolean()
  @IsOptional()
  completed?: boolean;
}
